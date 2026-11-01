import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../api/film_api.dart';
import '../../models/film_models.dart';
import '../../services/server_compat.dart';

/// 弹幕渲染层组件，对齐鸿蒙端 `PlayerDanmakuLayer.ets` 与 Web 端 `artplayer-plugin-danmuku`
class PlayerDanmakuLayer extends StatefulWidget {
  final String filmId;
  final int episode;
  final String filmTitle;
  final double currentTime;
  final bool isPlaying;
  final bool isBuffering;
  final double playbackSpeed;
  final bool enabled;

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
  });

  @override
  State<PlayerDanmakuLayer> createState() => _PlayerDanmakuLayerState();
}

class _ActiveDanmaku {
  final String text;
  final Color color;
  final int mode; // 0: 滚动, 1: 顶部固定, 2: 底部固定
  final double time;
  final int track;
  final double width;
  final double height;
  double x;
  double y;
  final double speed;
  double remainSec;

  _ActiveDanmaku({
    required this.text,
    required this.color,
    required this.mode,
    required this.time,
    required this.track,
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
  static const double _trackHeight = 28.0;
  static const double _fontSize = 14.0;
  static const double _scrollDuration = 7.0; // 滚动横屏时间 7 秒
  static const double _fixedDuration = 4.0;  // 固定弹幕停留 4 秒

  List<DanmakuComment> _allComments = [];
  final List<_ActiveDanmaku> _activeList = [];
  final Map<int, double> _fixedTopFreeTime = {};
  final Map<int, double> _fixedBottomFreeTime = {};

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

  Future<void> _loadDanmaku() async {
    final title = cleanTitle(widget.filmTitle);
    final curKey = '${widget.filmId}_${widget.episode}_$title';
    if (_loadKey == curKey) return;
    _loadKey = curKey;

    _activeList.clear();
    _fixedTopFreeTime.clear();
    _fixedBottomFreeTime.clear();
    _nextIndex = 0;
    _allComments = [];

    if (!ServerCompat.instance.canDanmaku || (widget.filmId.trim().isEmpty && title.isEmpty)) return;

    try {
      final list = await FilmApi.getDanmaku(
        widget.filmId,
        widget.episode,
        title,
      );
      if (!mounted || _loadKey != curKey) return;

      list.sort((a, b) => a.time.compareTo(b.time));
      setState(() {
        _allComments = list;
        _handleSeek(_currentVideoTime);
      });
      _syncTickerState();
    } catch (_) {}
  }

  double _getScrollSpeed() {
    // 恒定流速：同一视口下所有滚动弹幕速度一致，两车间距恒定不变，杜绝长短文本速度差异引发的追尾重叠
    return math.max(60.0, (_layoutSize.width + 160.0) / _scrollDuration);
  }

  int _calculateMaxTracks(double usableHeight) {
    final isLandscape = _layoutSize.width > _layoutSize.height;
    if (isLandscape) {
      final tracks = (usableHeight * 0.38) ~/ _trackHeight;
      return math.min(5, math.max(3, tracks));
    }
    final tracks = (usableHeight * 0.50) ~/ _trackHeight;
    return math.min(4, math.max(2, tracks));
  }

  void _handleSeek(double seekTime) {
    _activeList.clear();
    _fixedTopFreeTime.clear();
    _fixedBottomFreeTime.clear();

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

    final minTime = seekTime - _scrollDuration;
    var startIdx = low - 1;
    while (startIdx >= 0 && _allComments[startIdx].time >= minTime) {
      startIdx--;
    }
    startIdx = math.max(0, startIdx + 1);

    final usableHeight = math.max(60.0, _layoutSize.height - 40.0);
    final maxTracks = _calculateMaxTracks(usableHeight);
    final maxActive = (_layoutSize.width > _layoutSize.height) ? 36 : 20;

    for (var i = startIdx; i < low; i++) {
      if (_activeList.length >= maxActive) break;
      final c = _allComments[i];
      final elapsed = seekTime - c.time;
      if (elapsed < 0 || elapsed >= _scrollDuration) continue;
      _spawnSingleComment(c, maxTracks, elapsed: elapsed);
    }
  }

  void _spawnBetween(double fromTime, double toTime) {
    if (!widget.enabled || _layoutSize.width <= 0 || _layoutSize.height <= 0) return;

    final usableHeight = math.max(60.0, _layoutSize.height - 40.0);
    final maxTracks = _calculateMaxTracks(usableHeight);
    final maxActive = (_layoutSize.width > _layoutSize.height) ? 36 : 20;
    var spawnedThisTick = 0;

    while (_nextIndex < _allComments.length) {
      final c = _allComments[_nextIndex];
      if (c.time > toTime) break;
      _nextIndex++;

      if (c.time < fromTime - 0.5) continue;
      if (_activeList.length >= maxActive) continue;
      if (spawnedThisTick >= 4) continue;
      final elapsed = math.max(0.0, toTime - c.time);
      if (_spawnSingleComment(c, maxTracks, elapsed: elapsed)) {
        spawnedThisTick++;
      }
    }
  }

  bool _spawnSingleComment(DanmakuComment c, int maxTracks, {double elapsed = 0.0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: c.text,
        style: const TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final itemWidth = tp.width + 6.0;
    final itemHeight = tp.height;
    final color = _parseColor(c.color);

    if (c.mode == 0) {
      final speed = _getScrollSpeed();
      final startX = _layoutSize.width - (speed * elapsed);
      if (startX + itemWidth < -10) return false;

      var bestTrack = -1;

      // 工业级物理右边缘防撞判定：检查该轨道当前在屏的最右侧弹幕实体
      for (var t = 0; t < maxTracks; t++) {
        _ActiveDanmaku? rightmost;
        for (final act in _activeList) {
          if (act.mode == 0 && act.track == t) {
            if (rightmost == null || (act.x + act.width > rightmost.x + rightmost.width)) {
              rightmost = act;
            }
          }
        }

        // 该轨当前无在屏弹幕：立即可用
        if (rightmost == null) {
          bestTrack = t;
          break;
        }

        // 该轨已有在屏弹幕：前车尾部 + 32vp 安全空隙必须在当前新车入场位置左侧，杜绝压车重叠
        if (rightmost.x + rightmost.width + 32.0 <= startX) {
          bestTrack = t;
          break;
        }
      }

      // 所有可用轨道均在通行占用中：坚决丢弃，杜绝强行取模重叠覆盖
      if (bestTrack < 0) return false;

      final item = _ActiveDanmaku(
        text: c.text,
        color: color,
        mode: 0,
        time: c.time,
        track: bestTrack,
        width: itemWidth,
        height: itemHeight,
        x: startX,
        y: 8.0 + bestTrack * _trackHeight,
        speed: speed,
        remainSec: math.max(0.1, _scrollDuration - elapsed),
      );

      _activeList.add(item);
      return true;
    } else if (c.mode == 1) {
      if (elapsed >= _fixedDuration) return false;
      final maxFixedTracks = math.min(3, math.max(1, maxTracks ~/ 2));
      var bestTrack = -1;
      for (var t = 0; t < maxFixedTracks; t++) {
        final freeTime = _fixedTopFreeTime[t] ?? 0.0;
        if (c.time >= freeTime) {
          bestTrack = t;
          break;
        }
      }
      if (bestTrack < 0) return false; // 固定弹幕占满，坚决不重叠
      _fixedTopFreeTime[bestTrack] = c.time + _fixedDuration;

      final item = _ActiveDanmaku(
        text: c.text,
        color: color,
        mode: 1,
        time: c.time,
        track: bestTrack,
        width: itemWidth,
        height: itemHeight,
        x: math.max(0.0, (_layoutSize.width - itemWidth) / 2),
        y: 8.0 + bestTrack * _trackHeight,
        speed: 0,
        remainSec: math.max(0.1, _fixedDuration - elapsed),
      );
      _activeList.add(item);
      return true;
    } else {
      if (elapsed >= _fixedDuration) return false;
      final maxFixedTracks = math.min(3, math.max(1, maxTracks ~/ 2));
      var bestTrack = -1;
      for (var t = 0; t < maxFixedTracks; t++) {
        final freeTime = _fixedBottomFreeTime[t] ?? 0.0;
        if (c.time >= freeTime) {
          bestTrack = t;
          break;
        }
      }
      if (bestTrack < 0) return false; // 固定弹幕占满，坚决不重叠
      _fixedBottomFreeTime[bestTrack] = c.time + _fixedDuration;

      final item = _ActiveDanmaku(
        text: c.text,
        color: color,
        mode: 2,
        time: c.time,
        track: bestTrack,
        width: itemWidth,
        height: itemHeight,
        x: math.max(0.0, (_layoutSize.width - itemWidth) / 2),
        y: math.max(8.0, _layoutSize.height - 36.0 - bestTrack * _trackHeight),
        speed: 0,
        remainSec: math.max(0.1, _fixedDuration - elapsed),
      );
      _activeList.add(item);
      return true;
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_isActuallyPlaying) return;

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
      if (item.mode == 0) {
        item.x -= item.speed * dt * speedFactor;
        if (item.x + item.width < -10) {
          _activeList.removeAt(i);
        }
      } else {
        item.remainSec -= dt * speedFactor;
        if (item.remainSec <= 0) {
          _activeList.removeAt(i);
        }
      }
    }

    setState(() {});
  }

  Color _parseColor(String raw) {
    var hex = raw.replaceAll('#', '').trim();
    if (hex.length == 6) {
      hex = 'FF$hex';
    } else if (hex.length != 8) {
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
          if (_layoutSize != Size.zero &&
              (_layoutSize.height != newSize.height || _layoutSize.width != newSize.width)) {
            // 方向或尺寸发生变换：彻底清空旧尺寸下的所有悬浮弹幕与轨道，以当前视频进度平滑出字
            _activeList.clear();
            _fixedTopFreeTime.clear();
            _fixedBottomFreeTime.clear();
            _handleSeek(_currentVideoTime);
          }
          _layoutSize = newSize;

          return IgnorePointer(
            child: Opacity(
              opacity: 0.76, // 降低透明度，柔和融入画面，不遮挡主体内容
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
    for (final item in danmakuList) {
      if (item.y + item.height > size.height) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: item.color.withValues(alpha: 0.88),
            shadows: const [
              Shadow(color: Color(0x99000000), offset: Offset(1.0, 1.0), blurRadius: 2.0),
              Shadow(color: Color(0x99000000), offset: Offset(-1.0, -1.0), blurRadius: 2.0),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(item.x, item.y));
    }
  }

  @override
  bool shouldRepaint(covariant _DanmakuPainter oldDelegate) => true;
}
