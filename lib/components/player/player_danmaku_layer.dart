import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../api/film_api.dart';
import '../../models/film_models.dart';
import '../../services/server_compat.dart';
import 'danmaku_status.dart';

/// 弹幕渲染层组件，对齐鸿蒙端 `PlayerDanmakuLayer.ets` 与 Web 端 `artplayer-plugin-danmuku`
///
/// 排版模型（两端一致）：
/// - 整个可用高度切成统一行网格，行高由实测文字高度 + 描边阴影 + 高亮边框留白 + 行间隙算出，
///   保证相邻两行文字上下不重叠。
/// - 滚动弹幕只用上方 [_scrollAreaRatio] 比例的行；行满时（仅全屏级别的大播放器）再用错开半行的第二层，
///   第二层与它跨的两行做真实的横向区间碰撞检测，绝不压在已用的相邻行上；仍满则进入等待队列，
///   最多等 [_maxWaitSec] 秒，等不到才丢弃（不再一满就丢）。
/// - 顶部固定弹幕从第 0 行往下、底部固定弹幕从最后一行往上各自占行，居中停留 [_fixedDuration] 秒；
///   被固定弹幕占住的行，新的滚动弹幕会避开。
/// - 每条弹幕使用自身颜色；`border == true` 的高亮弹幕加粗并绘制圆角边框。
class PlayerDanmakuLayer extends StatefulWidget {
  final String filmId;
  final int episode;
  final String filmTitle;
  final double currentTime;
  final bool isPlaying;
  final bool isBuffering;
  final double playbackSpeed;
  final bool enabled;

  /// 弹幕加载状态变化（加载中 / 装载完成 / 失败），由控制条显示，不画在视频上
  final ValueChanged<DanmakuStatus>? onStatus;

  /// 仅测试用：直接注入弹幕列表，跳过网络请求
  @visibleForTesting
  final List<DanmakuComment>? debugComments;

  /// 仅测试用：每帧回报在屏弹幕统计
  @visibleForTesting
  final void Function(DanmakuLayerStats stats)? debugOnFrame;

  const PlayerDanmakuLayer({
    super.key,
    required this.filmId,
    required this.episode,
    required this.filmTitle,
    required this.currentTime,
    required this.isPlaying,
    this.isBuffering = false,
    this.playbackSpeed = 1.0,
    this.enabled = true,
    this.onStatus,
    this.debugComments,
    this.debugOnFrame,
  });

  @override
  State<PlayerDanmakuLayer> createState() => _PlayerDanmakuLayerState();
}

/// 在屏弹幕统计（测试与调试用）
@visibleForTesting
class DanmakuLayerStats {
  final int scroll;
  final int top;
  final int bottom;
  final int highlighted;
  final int pending;
  final int colored;
  /// 同类弹幕之间是否有两条文字矩形相互重叠（上下或左右）
  final bool hasOverlap;

  const DanmakuLayerStats({
    required this.scroll,
    required this.top,
    required this.bottom,
    required this.highlighted,
    required this.pending,
    required this.colored,
    required this.hasOverlap,
  });
}

class _ActiveDanmaku {
  final TextPainter painter;
  final Color color;
  final bool border;
  final int mode; // 0: 滚动, 1: 顶部固定, 2: 底部固定
  final double time;
  final int lane; // 滚动：layer * 100 + row；固定：固定行序号
  final int row; // 在统一行网格里的起始行
  final int rowSpan; // 占几行（第二层滚动弹幕跨两行）
  final double width;
  final double height;
  double x;
  double y;
  final double speed;
  double remainSec;

  _ActiveDanmaku({
    required this.painter,
    required this.color,
    required this.border,
    required this.mode,
    required this.time,
    required this.lane,
    required this.row,
    required this.rowSpan,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.speed,
    required this.remainSec,
  });
}

class _PlayerDanmakuLayerState extends State<PlayerDanmakuLayer>
    with SingleTickerProviderStateMixin {
  static const double _fontSize = 14.0;
  static const double _shadowExtent = 2.0; // 阴影偏移 1 + 模糊 2 向上下各溢出约 2
  static const double _borderExtent = 1.5; // 高亮圆角框比文字上下各多出 1.5
  static const double _rowGap = 2.0; // 相邻两行之间额外留白
  static const int _offsetLayerMinRows = 10; // 行数不足时（小窗/竖屏）禁用错开半行的第二层
  static const double _scrollDuration = 7.0; // 滚动横屏时间 7 秒
  static const double _fixedDuration = 4.0; // 固定弹幕停留 4 秒
  static const double _laneGap = 20.0; // 同一行前后两条弹幕的最小间距
  static const double _maxWaitSec = 2.0; // 行满时最多排队等待的视频时长
  static const double _catchUpWindow = 2.0; // 时钟对齐跳跃后，仍然补发的最大滞后
  static const int _maxPending = 300;
  static const int _maxSpawnPerTick = 16;
  static const double _topPad = 6.0;
  static const double _bottomPad = 10.0;
  static const double _layerOpacity = 0.82;

  /// 实测行高（字体度量 + 阴影 + 高亮框 + 间隙），首次使用时计算一次
  double? _rowHeightCache;
  double _textHeightCache = 0;

  double get _rowHeight {
    final cached = _rowHeightCache;
    if (cached != null) return cached;
    // 用中英混排样本测量（CJK 回退字体行高明显大于 Latin），并用最粗的高亮字重
    final tp = TextPainter(
      text: const TextSpan(
        text: '国Ag弹幕',
        style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    _textHeightCache = tp.height;
    tp.dispose();
    final h = (_textHeightCache + 2 * math.max(_shadowExtent, _borderExtent) + _rowGap).ceilToDouble();
    _rowHeightCache = h;
    return h;
  }

  List<DanmakuComment> _allComments = [];
  final List<_ActiveDanmaku> _activeList = [];
  final List<DanmakuComment> _pending = [];
  final List<_ActiveDanmaku> _retired = [];

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _currentVideoTime = 0.0;
  int _nextIndex = 0;
  String _loadKey = '';
  Size _layoutSize = Size.zero;

  static String cleanTitle(String raw) {
    var s = raw.trim();
    final dotIdx = s.indexOf('·');
    if (dotIdx > 0) {
      s = s.substring(0, dotIdx).trim();
    }
    return s;
  }

  @override
  void initState() {
    super.initState();
    _currentVideoTime = widget.currentTime;
    _ticker = createTicker(_onTick);
    _loadDanmaku();
    _syncTickerState();
  }

  @override
  void didUpdateWidget(covariant PlayerDanmakuLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keyChanged = oldWidget.filmId != widget.filmId ||
        oldWidget.episode != widget.episode ||
        cleanTitle(oldWidget.filmTitle) != cleanTitle(widget.filmTitle);

    if (keyChanged) {
      _loadDanmaku();
    }

    // 播放器时间大跨度漂移（快进/快退/切集偏差大于 2.0 秒）时才全量重排游标与在屏弹幕
    final drift = (widget.currentTime - _currentVideoTime).abs();
    if (drift > 2.0) {
      _currentVideoTime = widget.currentTime;
      _handleSeek(_currentVideoTime);
    } else if (drift > 0.4) {
      _currentVideoTime = widget.currentTime;
    }

    if (oldWidget.isPlaying != widget.isPlaying ||
        oldWidget.isBuffering != widget.isBuffering ||
        oldWidget.enabled != widget.enabled) {
      _syncTickerState();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    _retireAll();
    _flushRetired();
    super.dispose();
  }

  bool get _isActuallyPlaying =>
      widget.enabled && widget.isPlaying && !widget.isBuffering;

  void _syncTickerState() {
    if (_isActuallyPlaying) {
      if (_ticker != null && !_ticker!.isActive) {
        _lastTick = Duration.zero;
        _ticker!.start();
      }
    } else {
      if (_ticker != null && _ticker!.isActive) {
        _ticker!.stop();
      }
    }
  }

  /// 已移出屏幕的弹幕延后一帧再释放 TextPainter：本帧的 CustomPainter 可能还引用着它
  void _retireAll() {
    _retired.addAll(_activeList);
    _activeList.clear();
  }

  void _flushRetired() {
    for (final item in _retired) {
      item.painter.dispose();
    }
    _retired.clear();
  }

  Future<void> _loadDanmaku() async {
    final title = cleanTitle(widget.filmTitle);
    final curKey = '${widget.filmId}_${widget.episode}_$title';
    if (_loadKey == curKey) return;
    _loadKey = curKey;

    _retireAll();
    _pending.clear();
    _nextIndex = 0;
    _allComments = [];

    final injected = widget.debugComments;
    if (injected == null &&
        (!ServerCompat.instance.canDanmaku || (widget.filmId.trim().isEmpty && title.isEmpty))) {
      return;
    }

    widget.onStatus?.call(DanmakuStatus.loading);
    List<DanmakuComment> list = [];
    DanmakuStatus status;
    try {
      if (injected != null) {
        list = List<DanmakuComment>.of(injected);
        status = DanmakuStatus.loaded(list.length, null);
      } else {
        final res = await FilmApi.getDanmaku(
          widget.filmId,
          widget.episode,
          title,
        );
        list = res.list;
        status = DanmakuStatus.loaded(list.length, res.meta);
      }
    } on TimeoutException {
      status = DanmakuStatus.requestFailed('请求超时');
    } catch (e) {
      status = DanmakuStatus.requestFailed('$e'.replaceFirst('Exception: ', '').trim());
    }
    if (!mounted || _loadKey != curKey) return;
    widget.onStatus?.call(status);

    list.sort((a, b) => a.time.compareTo(b.time));
    setState(() {
      _allComments = list;
      _handleSeek(_currentVideoTime);
    });
    _syncTickerState();
  }

  bool get _isLandscape => _layoutSize.width > _layoutSize.height;

  double _getScrollSpeed() {
    // 恒定流速：同一视口下所有滚动弹幕速度一致，两车间距恒定不变，杜绝长短文本速度差异引发的追尾重叠
    return math.max(60.0, (_layoutSize.width + 160.0) / _scrollDuration);
  }

  /// 整个可用高度上的行数
  int get _totalRows {
    final usable = _layoutSize.height - _topPad - _bottomPad;
    return math.max(1, usable ~/ _rowHeight);
  }

  /// 滚动弹幕显示区域：横屏上方约一半，竖屏小窗约 3/4（小窗行数本来就少）
  double get _scrollAreaRatio => _isLandscape ? 0.55 : 0.75;

  int get _scrollRows {
    final total = _totalRows;
    final rows = (total * _scrollAreaRatio).floor();
    return math.min(16, math.max(math.min(2, total), rows));
  }

  /// 顶部、底部固定弹幕各自最多占几行
  int get _fixedRows => math.max(1, math.min(4, _totalRows ~/ 3));

  int get _maxActive => _isLandscape ? 150 : 80;

  double _rowY(int row) => _topPad + row * _rowHeight;

  /// 错开半行的第二层只在大播放器（横屏且行数充足，即全屏级别）启用
  bool get _allowOffsetLayer => _isLandscape && _totalRows >= _offsetLayerMinRows;

  /// 候选位置（起始行 row、跨 span 行、横向区间 [x, x+w]）是否与在屏滚动弹幕冲突。
  /// 所有滚动弹幕同速，相对位置恒定，所以只需比较当前横向区间。
  bool _scrollBlocked(int row, int span, double x, double w) {
    for (final act in _activeList) {
      if (act.mode != 0) continue;
      final rowsIntersect = act.row < row + span && row < act.row + act.rowSpan;
      if (!rowsIntersect) continue;
      final separated = act.x + act.width + _laneGap <= x || x + w + _laneGap <= act.x;
      if (!separated) return true;
    }
    return false;
  }

  /// 被在屏固定弹幕占用的行
  Set<int> _fixedOccupiedRows() {
    final rows = <int>{};
    for (final act in _activeList) {
      if (act.mode != 0) rows.add(act.row);
    }
    return rows;
  }

  void _handleSeek(double seekTime) {
    _retireAll();
    _pending.clear();

    if (_allComments.isEmpty) {
      _nextIndex = 0;
      return;
    }

    // 1. 二分查找第一个 time >= seekTime 的弹幕索引
    var low = 0;
    var high = _allComments.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_allComments[mid].time < seekTime) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    _nextIndex = low;

    if (!widget.enabled || _layoutSize.width <= 0 || _layoutSize.height <= 0) return;

    // 2. 回填最近 7 秒内本应在屏的弹幕（按各自已飞行时长摆位，排不下的直接跳过，不进队列）
    final minTime = seekTime - _scrollDuration;
    var startIdx = low - 1;
    while (startIdx >= 0 && _allComments[startIdx].time >= minTime) {
      startIdx--;
    }
    startIdx = math.max(0, startIdx + 1);

    final maxActive = _maxActive;
    for (var i = startIdx; i < low; i++) {
      if (_activeList.length >= maxActive) break;
      final c = _allComments[i];
      final elapsed = seekTime - c.time;
      if (elapsed < 0 || elapsed >= _scrollDuration) continue;
      _spawnSingleComment(c, elapsed: elapsed);
    }
  }

  void _spawnBetween(double fromTime, double toTime) {
    if (!widget.enabled || _layoutSize.width <= 0 || _layoutSize.height <= 0) return;

    final maxActive = _maxActive;
    var spawnedThisTick = 0;
    // 本帧某类弹幕（滚动 / 顶部 / 底部）已经排不下时，同类后续弹幕直接留在队列，不再逐条重试
    final full = <int>{};

    bool trySpawn(DanmakuComment c, double elapsed) {
      final mode = _modeOf(c);
      if (full.contains(mode) || spawnedThisTick >= _maxSpawnPerTick || _activeList.length >= maxActive) {
        return false;
      }
      if (_spawnSingleComment(c, elapsed: elapsed)) {
        spawnedThisTick++;
        return true;
      }
      full.add(mode);
      return false;
    }

    // 1. 先处理排队中的弹幕（先来先上），超过等待上限的丢弃
    if (_pending.isNotEmpty) {
      final keep = <DanmakuComment>[];
      for (final c in _pending) {
        if (toTime - c.time > _maxWaitSec) continue;
        if (!trySpawn(c, 0.0)) keep.add(c);
      }
      _pending
        ..clear()
        ..addAll(keep);
    }

    // 2. 时间轴上新到点的弹幕
    while (_nextIndex < _allComments.length) {
      final c = _allComments[_nextIndex];
      if (c.time > toTime) break;
      _nextIndex++;

      // 时钟对齐跳跃造成的滞后在 2 秒内仍补发（按已飞行时长摆位），更早的视为过期
      if (toTime - c.time > _catchUpWindow) continue;

      if (!trySpawn(c, math.max(0.0, toTime - c.time))) _enqueue(c);
    }
  }

  static int _modeOf(DanmakuComment c) => c.mode == 1 ? 1 : (c.mode == 2 ? 2 : 0);

  void _enqueue(DanmakuComment c) {
    if (_pending.length >= _maxPending) {
      _pending.removeAt(0);
    }
    _pending.add(c);
  }

  TextPainter _buildPainter(DanmakuComment c, Color color) {
    final isDark = color.computeLuminance() < 0.18;
    final shadowColor = isDark ? const Color(0xCCFFFFFF) : const Color(0xB3000000);
    return TextPainter(
      text: TextSpan(
        text: c.text,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: c.border ? FontWeight.w800 : FontWeight.w600,
          color: color,
          shadows: [
            Shadow(color: shadowColor, offset: const Offset(1.0, 1.0), blurRadius: 2.0),
            Shadow(color: shadowColor, offset: const Offset(-1.0, -1.0), blurRadius: 2.0),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  /// 为滚动弹幕挑一条可用的行：第 0 层整行；大播放器上第 0 层全满时启用错开半行、跨两行的第 1 层。
  /// 宽度越大越难放下，所以 w 传 0 可作为测量文字前的预检：预检都放不下就一定放不下。
  ({int lane, int row, int span, double y})? _pickScrollLane(double startX, double w) {
    final occupied = _fixedOccupiedRows();
    final scrollRows = _scrollRows;
    final rowH = _rowHeight;
    final layers = _allowOffsetLayer ? 2 : 1;
    for (var layer = 0; layer < layers; layer++) {
      final span = layer == 0 ? 1 : 2;
      final rowsInLayer = scrollRows - (span - 1);
      for (var r = 0; r < rowsInLayer; r++) {
        var blocked = false;
        for (var k = 0; k < span; k++) {
          if (occupied.contains(r + k)) blocked = true;
        }
        if (blocked || _scrollBlocked(r, span, startX, w)) continue;
        return (lane: layer * 100 + r, row: r, span: span, y: _rowY(r) + layer * rowH / 2);
      }
    }
    return null;
  }

  /// 为固定弹幕挑一条空闲的固定行（顶部从上往下、底部从下往上），没有时返回 -1
  int _pickFixedLane(int mode) {
    final maxFixed = _fixedRows;
    for (var t = 0; t < maxFixed; t++) {
      var busy = false;
      for (final act in _activeList) {
        if (act.mode == mode && act.lane == t) {
          busy = true;
          break;
        }
      }
      if (!busy) return t;
    }
    return -1;
  }

  bool _spawnSingleComment(DanmakuComment c, {double elapsed = 0.0}) {
    final mode = _modeOf(c);
    if (mode != 0 && elapsed >= _fixedDuration) return false;

    final speed = _getScrollSpeed();
    final startX = _layoutSize.width - (speed * elapsed);
    final totalRows = _totalRows;
    final rowH = _rowHeight;

    // 先用不依赖文字宽度的条件判断有没有空位，行满时不再排版测量文字
    var fixedLane = -1;
    if (mode == 0) {
      if (_pickScrollLane(startX, 0) == null) return false;
    } else {
      fixedLane = _pickFixedLane(mode);
      if (fixedLane < 0) return false;
    }

    final color = _parseColor(c.color);
    final tp = _buildPainter(c, color);
    final pad = c.border ? 4.0 : 0.0;
    final itemWidth = tp.width + 6.0 + pad * 2;
    final itemHeight = tp.height;

    if (mode == 0 && startX + itemWidth < -10) {
      tp.dispose();
      return false;
    }

    int lane;
    int row;
    int rowSpan = 1;
    double y;

    if (mode == 0) {
      final pick = _pickScrollLane(startX, itemWidth);
      if (pick == null) {
        tp.dispose();
        return false; // 行满：由调用方决定排队还是放弃
      }
      lane = pick.lane;
      row = pick.row;
      rowSpan = pick.span;
      y = pick.y;
    } else {
      lane = fixedLane;
      row = mode == 1 ? lane : math.max(0, totalRows - 1 - lane);
      y = _rowY(row);
    }

    final x = mode == 0 ? startX : math.max(0.0, (_layoutSize.width - itemWidth) / 2);
    _activeList.add(_ActiveDanmaku(
      painter: tp,
      color: color,
      border: c.border,
      mode: mode,
      time: c.time,
      lane: lane,
      row: row,
      rowSpan: rowSpan,
      width: itemWidth,
      height: itemHeight,
      x: x,
      // 文字在行内垂直居中（第 1 层跨两行时居中于两行交界，与上下行文字仍有间隙）
      y: y + (rowH - itemHeight) / 2,
      speed: mode == 0 ? speed : 0,
      remainSec: mode == 0
          ? math.max(0.1, _scrollDuration - elapsed)
          : math.max(0.1, _fixedDuration - elapsed),
    ));
    return true;
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_isActuallyPlaying) return;

    // 上一帧移除的弹幕已经不在当前 CustomPainter 里，可以安全释放
    _flushRetired();

    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    if (dt <= 0 || dt > 0.1) return;

    final speedFactor = math.max(0.2, widget.playbackSpeed);
    final lastTime = _currentVideoTime;
    _currentVideoTime += dt * speedFactor;

    // 每一帧在时间线上发射新出现的弹幕（对齐 Web 与鸿蒙时钟引擎）
    _spawnBetween(lastTime, _currentVideoTime);

    for (var i = _activeList.length - 1; i >= 0; i--) {
      final item = _activeList[i];
      var remove = false;
      if (item.mode == 0) {
        item.x -= item.speed * dt * speedFactor;
        remove = item.x + item.width < -10;
      } else {
        item.remainSec -= dt * speedFactor;
        remove = item.remainSec <= 0;
      }
      if (remove) {
        _retired.add(_activeList.removeAt(i));
      }
    }

    setState(() {});
    final report = widget.debugOnFrame;
    if (report != null) report(_stats());
  }

  DanmakuLayerStats _stats() {
    var scroll = 0, top = 0, bottom = 0, highlighted = 0, colored = 0;
    var overlap = false;
    for (var i = 0; i < _activeList.length; i++) {
      final a = _activeList[i];
      if (a.mode == 0) {
        scroll++;
      } else if (a.mode == 1) {
        top++;
      } else {
        bottom++;
      }
      if (a.border) highlighted++;
      if (a.color.toARGB32() != 0xFFFFFFFF) colored++;
      for (var j = i + 1; j < _activeList.length; j++) {
        final b = _activeList[j];
        // 固定弹幕按设计会短暂盖在穿过的滚动弹幕上方，这里只统计同类弹幕之间的重叠
        if (a.mode != b.mode) continue;
        final vertical = a.y < b.y + b.height && b.y < a.y + a.height;
        final horizontal = a.x < b.x + b.width && b.x < a.x + a.width;
        if (vertical && horizontal) overlap = true;
      }
    }
    return DanmakuLayerStats(
      scroll: scroll,
      top: top,
      bottom: bottom,
      highlighted: highlighted,
      pending: _pending.length,
      colored: colored,
      hasOverlap: overlap,
    );
  }

  Color _parseColor(String raw) {
    var hex = raw.replaceAll('#', '').trim();
    if (hex.length == 6) {
      hex = 'FF$hex';
    } else if (hex.length == 8) {
      hex = 'FF${hex.substring(2)}';
    } else {
      return Colors.white;
    }
    final val = int.tryParse(hex, radix: 16);
    return val != null ? Color(val) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final newSize = Size(constraints.maxWidth, constraints.maxHeight);
          final resized = _layoutSize != Size.zero &&
              (_layoutSize.height != newSize.height || _layoutSize.width != newSize.width);
          _layoutSize = newSize;
          if (resized) {
            // 方向或尺寸发生变换：清空旧尺寸下的悬浮弹幕与轨道，以当前视频进度按新尺寸重排
            _handleSeek(_currentVideoTime);
          }

          return IgnorePointer(
            child: Opacity(
              opacity: _layerOpacity, // 柔和融入画面，不遮挡主体内容
              child: RepaintBoundary(
                child: CustomPaint(
                  size: _layoutSize,
                  painter: _DanmakuPainter(
                    danmakuList: List.of(_activeList),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DanmakuPainter extends CustomPainter {
  final List<_ActiveDanmaku> danmakuList;

  _DanmakuPainter({required this.danmakuList});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    Paint? borderPaint;
    Paint? fillPaint;
    for (final item in danmakuList) {
      if (item.y + item.height > size.height) continue;
      if (item.border) {
        borderPaint ??= Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        fillPaint ??= Paint()..color = const Color(0x40000000);
        borderPaint.color = item.color.withValues(alpha: 0.95);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(item.x, item.y - 1.5, item.width - 2.0, item.height + 3.0),
          Radius.circular((item.height + 3.0) / 2),
        );
        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, borderPaint);
        item.painter.paint(canvas, Offset(item.x + 6.0, item.y));
      } else {
        item.painter.paint(canvas, Offset(item.x, item.y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DanmakuPainter oldDelegate) => true;
}
