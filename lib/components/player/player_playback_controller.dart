import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'player_gesture_handler.dart';
import 'player_speed.dart';
import 'player_scale.dart';
import 'player_stall_watcher.dart';
import 'player_window.dart';

/// 播放器会话与播放状态控制器，管理生命周期、缓冲检测与控制指令
class PlayerPlaybackController extends ChangeNotifier {
  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isBuffering = false;
  bool get isBuffering => _isBuffering;

  bool _isOpening = true;
  bool get isOpening => _isOpening;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  bool _muted = false;
  bool get muted => _muted;

  String _errorText = '';
  String get errorText => _errorText;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;
  double get currentPositionSec => _currentPosition.inMilliseconds / 1000.0;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;
  double get totalDurationSec => _totalDuration.inMilliseconds / 1000.0;

  Duration? _dragPreviewPosition;
  Duration? get dragPreviewPosition => _dragPreviewPosition;
  Duration get displayPosition => _dragPreviewPosition ?? _currentPosition;

  double _currentSpeed = PlayerSpeed.defaultRate;
  double get currentSpeed => _currentSpeed;

  bool _showHud = true;
  bool get showHud => _showHud;

  PlayerPanState _panState = const PlayerPanState();
  PlayerPanState get panState => _panState;

  PlayerScaleMode _scaleMode = PlayerScale.defaultMode;
  PlayerScaleMode get scaleMode => _scaleMode;

  double _brightness = 0.5;
  double get brightness => _brightness;

  double _volume = 0.8;
  double get volume => _volume;

  final PlayerStallWatcher watcher = PlayerStallWatcher();
  int _initSessionId = 0;
  bool _hasSeekedInitial = false;
  int _lastPersistMs = 0;

  VoidCallback? onEnded;
  void Function(double current, double duration)? onProgress;
  VoidCallback? onStateChanged;

  bool get isReady => _controller != null && _controller!.value.isInitialized && !_isOpening;

  Future<void> loadWindowLevels() async {
    final b = await PlayerWindow.getBrightness();
    final v = await PlayerWindow.getVolume();
    _brightness = b;
    _volume = v;
    notifyListeners();
  }

  void _safeSetWakelock(bool enable) {
    try {
      if (enable) {
        WakelockPlus.enable().catchError((_) {});
      } else {
        WakelockPlus.disable().catchError((_) {});
      }
    } catch (_) {}
  }

  Future<void> initPlayer(String videoUrl, {double initialTime = 0, bool autoPlay = true}) async {
    final sessionId = ++_initSessionId;
    watcher.dispose();

    final oldController = _controller;
    _controller = null;
    if (oldController != null) {
      oldController.removeListener(_onControllerUpdate);
      try { await oldController.pause(); } catch (_) {}
      try { await oldController.dispose(); } catch (_) {}
    }

    if (sessionId != _initSessionId) return;
    _hasSeekedInitial = false;

    final url = videoUrl.trim();
    if (url.isEmpty) {
      _isOpening = false;
      _isBuffering = false;
      _isPlaying = false;
      _errorText = '未提供播放地址';
      notifyListeners();
      onStateChanged?.call();
      return;
    }

    _isOpening = true;
    _isBuffering = true;
    _isPlaying = false;
    _isCompleted = false;
    _errorText = '';
    _showHud = true;
    notifyListeners();
    onStateChanged?.call();

    watcher.armOpenWatch(() {
      if (sessionId != _initSessionId || !_isOpening) return;
      _isOpening = false;
      _isBuffering = false;
      _errorText = '视频打开超时(15s)';
      notifyListeners();
      onStateChanged?.call();
    }, isOpening: true);

    VideoPlayerController? newController;
    try {
      newController = VideoPlayerController.networkUrl(Uri.parse(url));
      await newController.initialize();
      if (sessionId != _initSessionId) {
        newController.dispose().catchError((_) {});
        return;
      }

      watcher.clearOpenWatch();
      newController.addListener(_onControllerUpdate);
      _controller = newController;

      if (initialTime > 0 && !_hasSeekedInitial) {
        _hasSeekedInitial = true;
        await newController.seekTo(Duration(seconds: initialTime.toInt()));
      }

      await newController.setPlaybackSpeed(_currentSpeed);
      await newController.setVolume(_muted ? 0.0 : 1.0);
      if (autoPlay) {
        await newController.play();
        _safeSetWakelock(true);
      } else {
        await newController.pause();
        _safeSetWakelock(false);
      }

      if (sessionId == _initSessionId) {
        _isOpening = false;
        _isBuffering = false;
        _errorText = '';
        _totalDuration = newController.value.duration;
        _isPlaying = autoPlay;
        armHideHud();
        notifyListeners();
        onStateChanged?.call();
      }
    } catch (e) {
      watcher.clearOpenWatch();
      newController?.dispose().catchError((_) {});
      if (_controller == newController) _controller = null;
      if (sessionId == _initSessionId) {
        _isOpening = false;
        _isBuffering = false;
        _isPlaying = false;
        _errorText = '视频加载失败: $e';
        notifyListeners();
        onStateChanged?.call();
      }
    }
  }

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null) return;
    final value = c.value;
    final playing = value.isPlaying;
    final buffering = value.isBuffering;
    final pos = value.position;
    final dur = value.duration;
    final completed = dur.inSeconds > 0 && pos >= dur && !buffering;

    // 当底层已经开始播放或有播放进度时，确保打开状态已解除
    if ((playing || pos > Duration.zero) && _isOpening) {
      _isOpening = false;
    }

    if (playing != _isPlaying ||
        buffering != _isBuffering ||
        pos != _currentPosition ||
        dur != _totalDuration ||
        completed != _isCompleted) {
      final justCompleted = completed && !_isCompleted;
      _isPlaying = playing;
      _isBuffering = buffering;
      _currentPosition = pos;
      _totalDuration = dur;
      _isCompleted = completed;
      watcher.clearSeekWatch();

      final now = DateTime.now().millisecondsSinceEpoch;
      if (onProgress != null && dur.inSeconds > 0 && _dragPreviewPosition == null) {
        if (completed || now - _lastPersistMs >= PlayerStallWatcher.progressPersistMs) {
          _lastPersistMs = now;
          onProgress!(pos.inSeconds.toDouble(), dur.inSeconds.toDouble());
        }
      }

      notifyListeners();
      onStateChanged?.call();
      if (justCompleted) onEnded?.call();
    }
  }

  void armHideHud() {
    watcher.armHide(() {
      if (_isPlaying && !_isCompleted && _panState.kind == PlayerTipKind.none) {
        _showHud = false;
        notifyListeners();
      }
    }, canHide: _isPlaying && !_isCompleted && _errorText.isEmpty);
  }

  void toggleHud() {
    if (_panState.kind != PlayerTipKind.none) return;
    _showHud = !_showHud;
    if (_showHud) {
      armHideHud();
    } else {
      watcher.clearHide();
    }
    notifyListeners();
  }

  void togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_isCompleted) {
      seekTo(Duration.zero);
      c.play();
      _safeSetWakelock(true);
      _isCompleted = false;
      _isPlaying = true;
      _showHud = true;
      armHideHud();
      notifyListeners();
      return;
    }
    if (c.value.isPlaying) {
      c.pause();
      _safeSetWakelock(false);
      _isPlaying = false;
      _isBuffering = false;
      _showHud = true;
      watcher.clearHide();
    } else {
      c.play();
      _safeSetWakelock(true);
      _isPlaying = true;
      armHideHud();
    }
    notifyListeners();
  }

  void play() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_isCompleted) {
      seekTo(Duration.zero);
      _isCompleted = false;
    }
    c.play();
    _safeSetWakelock(true);
    _isPlaying = true;
    notifyListeners();
  }

  void pause() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    c.pause();
    _safeSetWakelock(false);
    _isPlaying = false;
    _isBuffering = false;
    watcher.clearHide();
    notifyListeners();
  }

  /// 投屏绑定时释放销毁本地播放器，对标 OHOS `parkPlayerForCast`
  void parkForCast() {
    _initSessionId++;
    watcher.clearOpenWatch();
    watcher.clearSeekWatch();
    watcher.clearHide();
    _safeSetWakelock(false);
    _isPlaying = false;
    _isBuffering = false;
    _isOpening = false;
    _isCompleted = false;
    _errorText = '';
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onControllerUpdate);
      old.pause().catchError((_) {});
      old.dispose().catchError((_) {});
    }
    notifyListeners();
  }

  void pauseLocal() {
    _controller?.pause().catchError((_) {});
    _safeSetWakelock(false);
    _isPlaying = false;
    _isBuffering = false;
    notifyListeners();
  }

  void resumeLocal(double targetSec, bool wasPlaying) {
    seekTo(Duration(seconds: targetSec.toInt()));
    if (wasPlaying) {
      _controller?.play().catchError((_) {});
      _safeSetWakelock(true);
      _isPlaying = true;
      notifyListeners();
    } else {
      _controller?.pause().catchError((_) {});
      _safeSetWakelock(false);
      _isPlaying = false;
      notifyListeners();
    }
  }

  void remountCompleted(double positionSec, double durationSec) {
    _initSessionId++;
    watcher.clearOpenWatch();
    watcher.clearSeekWatch();
    watcher.clearHide();
    _safeSetWakelock(false);
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onControllerUpdate);
      old.pause().catchError((_) {});
      old.dispose().catchError((_) {});
    }
    _isPlaying = false;
    _isBuffering = false;
    _isOpening = false;
    _isCompleted = true;
    _errorText = '';
    _currentPosition = Duration(seconds: positionSec.toInt());
    if (durationSec > 0) {
      _totalDuration = Duration(seconds: durationSec.toInt());
    }
    notifyListeners();
  }

  void seekTo(Duration target) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    _dragPreviewPosition = null;
    _currentPosition = target;
    c.seekTo(target);
    watcher.armSeekWatch(() {
      showTransient(const PlayerPanState(kind: PlayerTipKind.seekFwd, text: 'Seek超时'));
    }, isSeeking: true);
    armHideHud();
    notifyListeners();
  }

  void setSpeed(double speed) {
    _currentSpeed = speed;
    _controller?.setPlaybackSpeed(speed);
    armHideHud();
    notifyListeners();
  }

  void cycleScale() {
    _scaleMode = PlayerScale.next(_scaleMode);
    showTransient(PlayerPanState(kind: PlayerTipKind.scale, text: '画面：${PlayerScale.label(_scaleMode)}'));
    notifyListeners();
  }

  void toggleMute() {
    _muted = !_muted;
    _controller?.setVolume(_muted ? 0.0 : 1.0);
    showTransient(PlayerPanState(kind: PlayerTipKind.volume, text: _muted ? '静音' : '音量 100%'));
    notifyListeners();
  }

  void setBrightness(double v) {
    _brightness = v;
    PlayerWindow.setBrightness(v);
    notifyListeners();
  }

  void setVolume(double v) {
    _volume = v;
    if (!_muted) PlayerWindow.setVolume(v);
    notifyListeners();
  }

  void setDragPreview(Duration? preview) {
    _dragPreviewPosition = preview;
    _showHud = true;
    watcher.clearHide();
    notifyListeners();
  }

  void setPanState(PlayerPanState state) {
    _panState = state;
    if (state.kind != PlayerTipKind.none) {
      watcher.clearHide();
    } else {
      armHideHud();
    }
    notifyListeners();
  }

  void showTransient(PlayerPanState state) {
    _panState = state;
    watcher.clearHide();
    watcher.showTip(() {
      if (_panState.kind == state.kind) {
        _panState = const PlayerPanState(kind: PlayerTipKind.none);
        armHideHud();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _initSessionId++;
    watcher.dispose();
    PlayerWindow.resetBrightness();
    _safeSetWakelock(false);
    final c = _controller;
    _controller = null;
    c?.removeListener(_onControllerUpdate);
    c?.dispose();
    super.dispose();
  }
}
