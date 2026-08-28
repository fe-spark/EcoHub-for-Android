import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'player_gesture_handler.dart';
import 'player_skin_view.dart';
import 'player_speed_sheet.dart';

/// 跨平台视频播放器容器组件
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String poster;
  final double initialTime;
  final bool showBack;
  final bool isFull;
  final bool hasPrev;
  final bool hasNext;
  final int reloadToken;
  final VoidCallback? onBack;
  final VoidCallback? onEnded;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<bool>? onFullscreenChange;
  final void Function(double current, double duration)? onProgress;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.title = '',
    this.poster = '',
    this.initialTime = 0,
    this.showBack = false,
    this.isFull = false,
    this.hasPrev = false,
    this.hasNext = false,
    this.reloadToken = 0,
    this.onBack,
    this.onEnded,
    this.onPrev,
    this.onNext,
    this.onFullscreenChange,
    this.onProgress,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isOpening = true;
  bool _isCompleted = false;
  bool _muted = false;
  String _errorText = '';
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration? _dragPreviewPosition;
  double _currentSpeed = 1.0;
  bool _showHud = true;
  Timer? _hideHudTimer;
  bool _hasSeekedInitial = false;
  PlayerPanState _panState = const PlayerPanState();

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl || oldWidget.reloadToken != widget.reloadToken) {
      _initPlayer();
    }
  }

  @override
  void dispose() {
    _hideHudTimer?.cancel();
    WakelockPlus.disable();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    _hideHudTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    await _controller?.dispose();
    _controller = null;
    _hasSeekedInitial = false;

    if (widget.videoUrl.trim().isEmpty) {
      setState(() {
        _isOpening = false;
        _isBuffering = false;
        _errorText = '未提供播放地址';
      });
      return;
    }

    setState(() {
      _isOpening = true;
      _isBuffering = true;
      _isCompleted = false;
      _errorText = '';
      _showHud = true;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl.trim()),
      );
      _controller = controller;

      await controller.initialize();
      controller.addListener(_onControllerUpdate);

      if (widget.initialTime > 0 && !_hasSeekedInitial) {
        _hasSeekedInitial = true;
        await controller.seekTo(Duration(seconds: widget.initialTime.toInt()));
      }

      await controller.setPlaybackSpeed(_currentSpeed);
      await controller.setVolume(_muted ? 0.0 : 1.0);
      await controller.play();
      WakelockPlus.enable();

      if (mounted) {
        setState(() {
          _isOpening = false;
          _isBuffering = false;
          _totalDuration = controller.value.duration;
          _isPlaying = true;
        });
        _armHideHud();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOpening = false;
          _isBuffering = false;
          _errorText = '视频加载失败: $e';
        });
      }
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || !mounted) return;

    final value = c.value;
    final isPlaying = value.isPlaying;
    final isBuffering = value.isBuffering;
    final pos = value.position;
    final dur = value.duration;
    final completed = dur.inSeconds > 0 && pos >= dur && !isBuffering;

    if (isPlaying != _isPlaying ||
        isBuffering != _isBuffering ||
        pos != _currentPosition ||
        dur != _totalDuration ||
        completed != _isCompleted) {
      setState(() {
        _isPlaying = isPlaying;
        _isBuffering = isBuffering;
        _currentPosition = pos;
        _totalDuration = dur;
        _isCompleted = completed;
      });

      if (widget.onProgress != null && dur.inSeconds > 0 && _dragPreviewPosition == null) {
        widget.onProgress!(pos.inSeconds.toDouble(), dur.inSeconds.toDouble());
      }

      if (completed) {
        if (widget.onEnded != null) {
          widget.onEnded!();
        }
      }
    }
  }

  void _armHideHud() {
    _hideHudTimer?.cancel();
    if (!_isPlaying || _isCompleted || _errorText.isNotEmpty) return;
    _hideHudTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying && !_isCompleted && _panState.kind == PlayerTipKind.none) {
        setState(() {
          _showHud = false;
        });
      }
    });
  }

  void _toggleHud() {
    if (_panState.kind != PlayerTipKind.none) return;
    setState(() {
      _showHud = !_showHud;
    });
    if (_showHud) {
      _armHideHud();
    } else {
      _hideHudTimer?.cancel();
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (_isCompleted) {
      _seekTo(Duration.zero);
      c.play();
      WakelockPlus.enable();
      setState(() {
        _isCompleted = false;
        _showHud = true;
      });
      _armHideHud();
      return;
    }
    if (c.value.isPlaying) {
      c.pause();
      WakelockPlus.disable();
      setState(() {
        _showHud = true;
      });
      _hideHudTimer?.cancel();
    } else {
      c.play();
      WakelockPlus.enable();
      _armHideHud();
    }
  }

  void _toggleFullscreen() {
    final nextFull = !widget.isFull;
    if (widget.onFullscreenChange != null) {
      widget.onFullscreenChange!(nextFull);
    }
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _controller?.setVolume(_muted ? 0.0 : 1.0);
    _panState = PlayerPanState(
      kind: PlayerTipKind.volume,
      text: _muted ? '静音' : '音量 100%',
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _panState.kind == PlayerTipKind.volume) {
        setState(() {
          _panState = const PlayerPanState(kind: PlayerTipKind.none);
        });
      }
    });
    _armHideHud();
  }

  void _seekTo(Duration target) {
    setState(() {
      _dragPreviewPosition = null;
      _currentPosition = target;
    });
    _controller?.seekTo(target);
    _armHideHud();
  }

  void _seekDelta(int seconds) {
    final cur = _currentPosition.inSeconds;
    final tot = _totalDuration.inSeconds;
    final targetSec = (cur + seconds).clamp(0, tot > 0 ? tot : 0);
    _seekTo(Duration(seconds: targetSec));
  }

  void _setSpeed(double speed) {
    _currentSpeed = speed;
    _controller?.setPlaybackSpeed(speed);
    _armHideHud();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final isInitialized = c != null && c.value.isInitialized;
    final displayPos = _dragPreviewPosition ?? _currentPosition;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频画面与底层手势识别
          PlayerGestureHandler(
            currentPosition: _currentPosition,
            totalDuration: _totalDuration,
            isPlaying: _isPlaying,
            isFull: widget.isFull,
            currentSpeed: _currentSpeed,
            onSingleTap: _toggleHud,
            onDoubleTap: _togglePlay,
            onSeekProgress: (preview) {
              setState(() {
                _dragPreviewPosition = preview;
                _showHud = true;
              });
              _hideHudTimer?.cancel();
            },
            onSeekEnd: (finalPos) {
              _seekTo(finalPos);
            },
            onSpeedChange: _setSpeed,
            onPanStateChange: (state) {
              setState(() {
                _panState = state;
              });
              if (state.kind != PlayerTipKind.none) {
                _hideHudTimer?.cancel();
              } else {
                _armHideHud();
              }
            },
            child: isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
                      child: VideoPlayer(c),
                    ),
                  )
                : (widget.poster.isNotEmpty
                    ? Image.network(
                        widget.poster,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      )
                    : const SizedBox.shrink()),
          ),

          // 上层控制皮肤（按钮事件完全独立响应，不会被手势拦截）
          PlayerSkinView(
            isFull: widget.isFull,
            showHud: _showHud,
            showBack: widget.showBack,
            title: widget.title,
            isPlaying: _isPlaying,
            isBuffering: _isBuffering,
            isOpening: _isOpening,
            isReady: isInitialized && !_isOpening,
            isCompleted: _isCompleted,
            muted: _muted,
            errorText: _errorText,
            currentPosition: displayPos,
            totalDuration: _totalDuration,
            currentSpeed: _currentSpeed,
            hasPrev: widget.hasPrev,
            hasNext: widget.hasNext,
            panState: _panState,
            onBack: () {
              if (widget.isFull) {
                _toggleFullscreen();
              } else if (widget.onBack != null) {
                widget.onBack!();
              }
            },
            onTogglePlay: _togglePlay,
            onToggleFull: _toggleFullscreen,
            onToggleMute: _toggleMute,
            onSpeed: () {
              PlayerSpeedSheet.show(context, _currentSpeed, _setSpeed);
            },
            onRetry: _initPlayer,
            onPrev: widget.onPrev,
            onNext: widget.onNext,
            onSeekBack10: () => _seekDelta(-10),
            onSeekFwd10: () => _seekDelta(10),
            onSeekTo: _seekTo,
          ),
        ],
      ),
    );
  }
}

