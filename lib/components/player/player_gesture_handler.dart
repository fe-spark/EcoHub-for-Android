import 'package:flutter/material.dart';
import '../../utils/format_util.dart';

enum PlayerTipKind { none, seekFwd, seekBack, brightness, volume, speed }

class PlayerPanState {
  final PlayerTipKind kind;
  final String text;
  final Duration? previewTime;

  const PlayerPanState({
    this.kind = PlayerTipKind.none,
    this.text = '',
    this.previewTime,
  });
}

/// 播放器手势控制层（支持横向拖动进度实时联动、纵向亮度/音量、长按2倍速）
class PlayerGestureHandler extends StatefulWidget {
  final Widget child;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final bool isFull;
  final double currentSpeed;
  final VoidCallback onSingleTap;
  final VoidCallback onDoubleTap;
  final ValueChanged<Duration> onSeekProgress;
  final ValueChanged<Duration> onSeekEnd;
  final ValueChanged<double> onSpeedChange;
  final void Function(PlayerPanState state) onPanStateChange;

  const PlayerGestureHandler({
    super.key,
    required this.child,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
    required this.isFull,
    this.currentSpeed = 1.0,
    required this.onSingleTap,
    required this.onDoubleTap,
    required this.onSeekProgress,
    required this.onSeekEnd,
    required this.onSpeedChange,
    required this.onPanStateChange,
  });

  @override
  State<PlayerGestureHandler> createState() => _PlayerGestureHandlerState();
}

class _PlayerGestureHandlerState extends State<PlayerGestureHandler> {
  double _brightness = 0.5;
  double _volume = 0.8;
  Duration _dragTargetPosition = Duration.zero;
  double _dragStartPositionSeconds = 0;
  Offset _dragStartOffset = Offset.zero;
  int _dragMode = 0; // 0: none, 1: pending, 2: seek, 3: brightness, 4: volume
  bool _isLongPressing = false;
  double _preLongPressSpeed = 1.0;

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    _dragStartOffset = details.localPosition;
    _dragStartPositionSeconds = widget.currentPosition.inSeconds.toDouble();
    _dragTargetPosition = widget.currentPosition;
    _dragMode = 1;
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final dx = details.localPosition.dx - _dragStartOffset.dx;
    final dy = details.localPosition.dy - _dragStartOffset.dy;
    final absDx = dx.abs();
    final absDy = dy.abs();

    if (_dragMode == 1) {
      if (absDx < 10 && absDy < 10) return;
      if (absDx > 15 && absDx > absDy * 1.1 && widget.totalDuration.inSeconds > 0) {
        _dragMode = 2; // Seek
      } else if (widget.isFull && absDy >= 15 && absDy > absDx * 1.1) {
        final isLeft = _dragStartOffset.dx <= constraints.maxWidth / 2;
        _dragMode = isLeft ? 3 : 4; // 3: brightness, 4: volume
      } else {
        return;
      }
    }

    if (_dragMode == 2) {
      final width = constraints.maxWidth > 0 ? constraints.maxWidth : 300.0;
      final totSec = widget.totalDuration.inSeconds.toDouble();
      final rangeSec = totSec > 600 ? 120.0 : (totSec > 180 ? 60.0 : 30.0);
      final deltaSec = (dx / width) * rangeSec;
      final targetSec = (_dragStartPositionSeconds + deltaSec).clamp(0.0, totSec);
      _dragTargetPosition = Duration(seconds: targetSec.round());
      final diff = _dragTargetPosition.inSeconds - _dragStartPositionSeconds.round();
      final sign = diff >= 0 ? '+$diff' : '$diff';
      final kind = diff >= 0 ? PlayerTipKind.seekFwd : PlayerTipKind.seekBack;
      final text = '${FormatUtil.duration(targetSec)} / ${FormatUtil.duration(totSec)}  ${sign}s';

      widget.onSeekProgress(_dragTargetPosition);
      widget.onPanStateChange(PlayerPanState(
        kind: kind,
        text: text,
        previewTime: _dragTargetPosition,
      ));
    } else if (_dragMode == 3) {
      final height = constraints.maxHeight > 0 ? constraints.maxHeight : 200.0;
      final delta = -dy / height * 1.5;
      _brightness = (_brightness + delta * 0.05).clamp(0.0, 1.0);
      _dragStartOffset = details.localPosition;
      final text = '${(_brightness * 100).round()}%';
      widget.onPanStateChange(PlayerPanState(
        kind: PlayerTipKind.brightness,
        text: text,
      ));
    } else if (_dragMode == 4) {
      final height = constraints.maxHeight > 0 ? constraints.maxHeight : 200.0;
      final delta = -dy / height * 1.5;
      _volume = (_volume + delta * 0.05).clamp(0.0, 1.0);
      _dragStartOffset = details.localPosition;
      final text = '${(_volume * 100).round()}%';
      widget.onPanStateChange(PlayerPanState(
        kind: PlayerTipKind.volume,
        text: text,
      ));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragMode == 2 && widget.totalDuration.inSeconds > 0) {
      widget.onSeekEnd(_dragTargetPosition);
    }
    _dragMode = 0;
    widget.onPanStateChange(const PlayerPanState(kind: PlayerTipKind.none));
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.isPlaying) return;
    _isLongPressing = true;
    _preLongPressSpeed = widget.currentSpeed;
    widget.onSpeedChange(2.0);
    widget.onPanStateChange(const PlayerPanState(
      kind: PlayerTipKind.speed,
      text: '2.0x 快速播放中',
    ));
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isLongPressing) return;
    _isLongPressing = false;
    widget.onSpeedChange(_preLongPressSpeed);
    widget.onPanStateChange(const PlayerPanState(kind: PlayerTipKind.none));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSingleTap,
          onDoubleTap: widget.onDoubleTap,
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          onPanStart: (d) => _onPanStart(d, constraints),
          onPanUpdate: (d) => _onPanUpdate(d, constraints),
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          child: widget.child,
        );
      },
    );
  }
}
