import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'player_gesture_handler.dart';
import 'player_skin_view.dart';
import 'player_speed_sheet.dart';
import 'player_speed.dart';
import 'player_scale.dart';
import 'player_stall_watcher.dart';
import 'player_window.dart';
import '../../utils/format_util.dart';

/// 跨平台视频播放器，对齐 OHOS `VideoPlayer`
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String poster;
  final double initialTime;
  final bool showBack;
  final bool isFull;
  final bool hasPrev;
  final bool hasNext;
  final bool pageActive;
  final bool edgeHud;
  final int reloadToken;
  final double topInset;
  final double leftInset;
  final double rightInset;
  final double bottomInset;
  final VoidCallback? onBack;
  final VoidCallback? onEnded;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final void Function(bool full, {bool isPortrait})? onFullscreenChange;
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
    this.pageActive = true,
    this.edgeHud = false,
    this.reloadToken = 0,
    this.topInset = 0,
    this.leftInset = 0,
    this.rightInset = 0,
    this.bottomInset = 0,
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
  double _currentSpeed = PlayerSpeed.defaultRate;
  bool _showHud = true;
  bool _hasSeekedInitial = false;
  PlayerPanState _panState = const PlayerPanState();
  PlayerScaleMode _scaleMode = PlayerScale.defaultMode;
  double _brightness = 0.5;
  double _volume = 0.8;
  int _lastPersistMs = 0;
  final PlayerStallWatcher _watcher = PlayerStallWatcher();

  @override
  void initState() {
    super.initState();
    _loadWindowLevels();
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
    _watcher.dispose();
    PlayerWindow.resetBrightness();
    WakelockPlus.disable();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadWindowLevels() async {
    final b = await PlayerWindow.getBrightness();
    final v = await PlayerWindow.getVolume();
    if (mounted) {
      setState(() {
        _brightness = b;
        _volume = v;
      });
    }
  }

  Future<void> _initPlayer() async {
    _watcher.dispose();
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
    _watcher.armOpenWatch(() {
      if (!mounted || !_isOpening) return;
      setState(() {
        _isOpening = false;
        _isBuffering = false;
        _errorText = '打开超时';
      });
    }, isOpening: true);

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl.trim()));
      _controller = controller;
      await controller.initialize();
      _watcher.clearOpenWatch();
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
      _watcher.clearOpenWatch();
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
    if (isPlaying != _isPlaying || isBuffering != _isBuffering || pos != _currentPosition || dur != _totalDuration || completed != _isCompleted) {
      setState(() {
        _isPlaying = isPlaying;
        _isBuffering = isBuffering;
        _currentPosition = pos;
        _totalDuration = dur;
        _isCompleted = completed;
      });
      _watcher.clearSeekWatch();
      final now = DateTime.now().millisecondsSinceEpoch;
      if (widget.onProgress != null && dur.inSeconds > 0 && _dragPreviewPosition == null) {
        if (completed || now - _lastPersistMs >= PlayerStallWatcher.progressPersistMs) {
          _lastPersistMs = now;
          widget.onProgress!(pos.inSeconds.toDouble(), dur.inSeconds.toDouble());
        }
      }
      if (completed) widget.onEnded?.call();
    }
  }

  void _armHideHud() {
    _watcher.armHide(() {
      if (mounted && _isPlaying && !_isCompleted && _panState.kind == PlayerTipKind.none) {
        setState(() => _showHud = false);
      }
    }, canHide: _isPlaying && !_isCompleted && _errorText.isEmpty);
  }

  void _toggleHud() {
    if (_panState.kind != PlayerTipKind.none) return;
    setState(() => _showHud = !_showHud);
    if (_showHud) {
      _armHideHud();
    } else {
      _watcher.clearHide();
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
      setState(() => _showHud = true);
      _watcher.clearHide();
    } else {
      c.play();
      WakelockPlus.enable();
      _armHideHud();
    }
  }

  bool _isPortraitVideo() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return false;
    return c.value.size.height > c.value.size.width;
  }

  void _toggleFullscreen() {
    widget.onFullscreenChange?.call(!widget.isFull, isPortrait: _isPortraitVideo());
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0.0 : 1.0);
    _showTransient(PlayerPanState(kind: PlayerTipKind.volume, text: _muted ? '静音' : '音量 100%'));
  }

  void _seekTo(Duration target) {
    setState(() {
      _dragPreviewPosition = null;
      _currentPosition = target;
    });
    _controller?.seekTo(target);
    _watcher.armSeekWatch(() {
      if (!mounted) return;
      _showTransient(const PlayerPanState(kind: PlayerTipKind.seekFwd, text: 'Seek超时'));
    }, isSeeking: true);
    _armHideHud();
  }

  void _seekDelta(int seconds) {
    final tot = _totalDuration.inSeconds;
    final targetSec = (_currentPosition.inSeconds + seconds).clamp(0, tot > 0 ? tot : 0);
    _seekTo(Duration(seconds: targetSec));
  }

  void _setSpeed(double speed) {
    _currentSpeed = speed;
    _controller?.setPlaybackSpeed(speed);
    _armHideHud();
  }

  void _cycleScale() {
    setState(() => _scaleMode = PlayerScale.next(_scaleMode));
    _showTransient(PlayerPanState(kind: PlayerTipKind.scale, text: '画面：${PlayerScale.label(_scaleMode)}'));
  }

  void _showTransient(PlayerPanState state) {
    setState(() => _panState = state);
    _watcher.clearHide();
    _watcher.showTip(() {
      if (mounted && _panState.kind == state.kind) {
        setState(() => _panState = const PlayerPanState(kind: PlayerTipKind.none));
        _armHideHud();
      }
    });
  }

  Widget _videoLayer(VideoPlayerController c) {
    final size = c.value.size;
    final w = size.width > 0 ? size.width : 16.0;
    final h = size.height > 0 ? size.height : 9.0;
    if (_scaleMode == PlayerScaleMode.fit) {
      return Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
          child: VideoPlayer(c),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: PlayerScale.boxFit(_scaleMode),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: w, height: h, child: VideoPlayer(c)),
      ),
    );
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
          PlayerGestureHandler(
            currentPosition: _currentPosition,
            totalDuration: _totalDuration,
            isPlaying: _isPlaying,
            isFull: widget.isFull,
            currentSpeed: _currentSpeed,
            currentBrightness: _brightness,
            currentVolume: _volume,
            onSingleTap: _toggleHud,
            onDoubleTap: _togglePlay,
            onSeekProgress: (preview) {
              setState(() {
                _dragPreviewPosition = preview;
                _showHud = true;
              });
              _watcher.clearHide();
            },
            onSeekEnd: _seekTo,
            onSpeedChange: _setSpeed,
            onBrightnessChange: (v) {
              _brightness = v;
              PlayerWindow.setBrightness(v);
            },
            onVolumeChange: (v) {
              _volume = v;
              if (!_muted) PlayerWindow.setVolume(v);
            },
            onPanStateChange: (state) {
              setState(() => _panState = state);
              if (state.kind != PlayerTipKind.none) {
                _watcher.clearHide();
              } else {
                _armHideHud();
              }
            },
            child: isInitialized
                ? _videoLayer(c)
                : (widget.poster.isNotEmpty
                    ? Image.network(
                        widget.poster,
                        headers: FormatUtil.imageHeaders(widget.poster),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      )
                    : const SizedBox.shrink()),
          ),
          PlayerSkinView(
            isFull: widget.isFull,
            edgeHud: widget.edgeHud,
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
            scaleLabel: PlayerScale.label(_scaleMode),
            hasPrev: widget.hasPrev,
            hasNext: widget.hasNext,
            panState: _panState,
            topInset: widget.topInset,
            leftInset: widget.leftInset,
            rightInset: widget.rightInset,
            bottomInset: widget.bottomInset,
            onBack: () {
              if (widget.isFull) {
                _toggleFullscreen();
              } else {
                widget.onBack?.call();
              }
            },
            onTogglePlay: _togglePlay,
            onToggleFull: _toggleFullscreen,
            onToggleMute: _toggleMute,
            onSpeed: () => PlayerSpeedSheet.show(context, _currentSpeed, _setSpeed),
            onScale: _cycleScale,
            onRetry: _initPlayer,
            onCopyError: () {
              Clipboard.setData(ClipboardData(text: _errorText));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制错误信息')));
            },
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
