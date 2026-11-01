import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../api/film_api.dart';
import '../../models/film_models.dart';

/// 弹幕渲染层组件，对齐鸿蒙端 `PlayerDanmakuLayer.ets` 与 Web 端 `artplayer-plugin-danmuku`
class PlayerDanmakuLayer extends StatefulWidget {
  final String filmId;
  final int episode;
  final String filmTitle;
  final double currentTime;
  final bool isPlaying;
  final double playbackSpeed;
  final bool enabled;

  const PlayerDanmakuLayer({
    super.key,
    required this.filmId,
    required this.episode,
    required this.filmTitle,
    required this.currentTime,
    required this.isPlaying,
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
  final Map<int, _ActiveDanmaku> _trackTail = {};

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

    // 播放器时间漂移（快进/快退/切集大于 1.2 秒）时重对齐游标
    final drift = (widget.currentTime - _currentVideoTime).abs();
    if (drift > 1.2) {
      _currentVideoTime = widget.currentTime;
      _handleSeek(_currentVideoTime);
    }

    if (oldWidget.isPlaying != widget.isPlaying || oldWidget.enabled != widget.enabled) {
      _syncTickerState();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  void _syncTickerState() {
    if (widget.enabled && widget.isPlaying) {
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
    _trackTail.clear();
    _nextIndex = 0;
    _allComments = [];

    if (widget.filmId.trim().isEmpty && title.isEmpty) return;

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
        _spawnBetween(math.max(0.0, _currentVideoTime - 1.0), _currentVideoTime);
      });
      _syncTickerState();
    } catch (_) {}
  }

  void _handleSeek(double seekTime) {
    _activeList.clear();
    _trackTail.clear();

    // 二分查找待发射弹幕起始位置
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
  }

  void _spawnBetween(double fromTime, double toTime) {
    if (!widget.enabled || _layoutSize.width <= 0 || _layoutSize.height <= 0) return;

    final maxTracks = math.max(1, (_layoutSize.height * 0.75) ~/ _trackHeight);

    while (_nextIndex < _allComments.length) {
      final c = _allComments[_nextIndex];
      if (c.time > toTime) break;
      _nextIndex++;

      if (c.time < fromTime - 0.5) continue;

      _spawnSingleComment(c, maxTracks);
    }
  }

  void _spawnSingleComment(DanmakuComment c, int maxTracks) {
    final tp = TextPainter(
      text: TextSpan(
        text: c.text,
        style: const TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final itemWidth = tp.width;
    final itemHeight = tp.height;
    final color = _parseColor(c.color);

    if (c.mode == 0) {
      // 滚动弹幕：分配碰撞最小或最新空闲轨道
      var bestTrack = 0;
      var minOverlap = double.infinity;

      for (var t = 0; t < maxTracks; t++) {
        final tail = _trackTail[t];
        if (tail == null || (tail.x + tail.width < _layoutSize.width - 24)) {
          bestTrack = t;
          minOverlap = 0;
          break;
        }
        final overlap = (tail.x + tail.width) - (_layoutSize.width - 24);
        if (overlap < minOverlap) {
          minOverlap = overlap;
          bestTrack = t;
        }
      }

      final speed = (_layoutSize.width + itemWidth) / _scrollDuration;
      final item = _ActiveDanmaku(
        text: c.text,
        color: color,
        mode: 0,
        time: c.time,
        track: bestTrack,
        width: itemWidth,
        height: itemHeight,
        x: _layoutSize.width,
        y: 8.0 + bestTrack * _trackHeight,
        speed: speed,
        remainSec: _scrollDuration,
      );

      _activeList.add(item);
      _trackTail[bestTrack] = item;
    } else if (c.mode == 1) {
      // 顶部固定弹幕
      final track = _activeList.where((d) => d.mode == 1).length % math.max<int>(1, maxTracks ~/ 2);
      final item = _ActiveDanmaku(
        text: c.text,
        color: color,
        mode: 1,
        time: c.time,
        track: track,
        width: itemWidth,
        height: itemHeight,
        x: math.max(0.0, (_layoutSize.width - itemWidth) / 2),
        y: 8.0 + track * _trackHeight,
        speed: 0,
        remainSec: _fixedDuration,
      );
      _activeList.add(item);
    } else {
      // 底部固定弹幕
      final track = _activeList.where((d) => d.mode == 2).length % math.max<int>(1, maxTracks ~/ 2);
      final item = _ActiveDanmaku(
        text: c.text,
        color: color,
        mode: 2,
        time: c.time,
        track: track,
        width: itemWidth,
        height: itemHeight,
        x: math.max(0.0, (_layoutSize.width - itemWidth) / 2),
        y: math.max(8.0, _layoutSize.height - 36.0 - track * _trackHeight),
        speed: 0,
        remainSec: _fixedDuration,
      );
      _activeList.add(item);
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !widget.enabled || !widget.isPlaying) return;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        _layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
        return IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              size: _layoutSize,
              painter: _DanmakuPainter(
                danmakuList: List.of(_activeList),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DanmakuPainter extends CustomPainter {
  final List<_ActiveDanmaku> danmakuList;

  _DanmakuPainter({required this.danmakuList});

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in danmakuList) {
      final tp = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: item.color,
            shadows: const [
              Shadow(color: Color(0xCC000000), offset: Offset(1.0, 1.0), blurRadius: 2.0),
              Shadow(color: Color(0xCC000000), offset: Offset(-1.0, -1.0), blurRadius: 2.0),
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
