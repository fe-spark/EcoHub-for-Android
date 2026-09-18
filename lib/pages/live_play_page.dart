import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/film_api.dart';
import '../api/http_client.dart';
import '../common/app_theme.dart';
import '../components/empty_state.dart';
import '../components/loading_view.dart';
import '../components/page_header.dart';
import '../components/player/live_play_panel.dart';
import '../components/player/video_player_widget.dart';
import '../models/film_models.dart';
import '../services/pip_manager.dart';
import '../utils/app_orientation.dart';
import '../utils/app_settings_manager.dart';
import '../utils/breakpoint.dart';
import '../utils/history_manager.dart';
import '../utils/play_navigation.dart';
import '../utils/play_resume.dart';
import '../utils/server_config_manager.dart';
import '../utils/source_guard.dart';

/// 采集源现场播放页，布局对齐自定义播放页（播放器 + 线路/选集/简介）
class LivePlayPage extends StatefulWidget {
  final String sourceId;
  final String sourceMid;
  final int episodeIndex;
  final double currentTime;

  const LivePlayPage({
    super.key,
    required this.sourceId,
    required this.sourceMid,
    this.episodeIndex = 0,
    this.currentTime = 0,
  });

  @override
  State<LivePlayPage> createState() => _LivePlayPageState();
}

class _LivePlayPageState extends State<LivePlayPage> with WidgetsBindingObserver {
  bool _loading = true;
  String _errorText = '';
  String _name = '';
  String _picture = '';
  String _plot = '';
  List<PlaySource> _sources = [];
  String _playingSourceId = '';
  int _episodeIndex = 0;
  String _playUrl = '';
  int _playToken = 0;
  String _playTitle = '';
  double _initialTime = 0;
  bool _isFull = false;
  bool _isPipActive = false;
  final GlobalKey _videoKey = GlobalKey();
  String _sourceName = '采集源';
  double _lastCurrentTime = 0;
  double _lastDuration = 0;
  bool _persistEnabled = true;

  String get _historyId => PlayNavigation.livePlayHistoryId(widget.sourceId, widget.sourceMid);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PipManager.instance.addListener(_onPipChanged);
    _isPipActive = PipManager.instance.isPipActive;
    _episodeIndex = widget.episodeIndex;
    _initialTime = widget.currentTime;
    _lastCurrentTime = _initialTime;
    HttpClient.instance.trackView('play', _historyId, 'LivePlayPage');
    SourceGuard.onReconnect(_onReconnect);
    _initPlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PipManager.instance.removeListener(_onPipChanged);
    if (_lastCurrentTime > 0) {
      _persistHistory(_lastCurrentTime, _lastDuration);
    }
    try {
      SystemChrome.setPreferredOrientations(kAutoRotationOrientations);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}
    SourceGuard.offReconnect(_onReconnect);
    super.dispose();
  }

  void _onPipChanged(bool active) {
    if (mounted && _isPipActive != active) {
      setState(() => _isPipActive = active);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _lastCurrentTime > 0) {
      _persistHistory(_lastCurrentTime, _lastDuration);
    }
  }

  void _onReconnect() {
    _persistEnabled = false;
    _loadPlay();
  }

  Future<void> _initPlay() async {
    if (widget.episodeIndex == 0 && widget.currentTime == 0 && _historyId.isNotEmpty) {
      final resume = await PlayResume.fromHistory(_historyId);
      _episodeIndex = resume.episodeIndex;
      _initialTime = resume.currentTime;
      _lastCurrentTime = resume.currentTime;
      _lastDuration = resume.duration;
    }
    await _loadPlay();
  }

  Future<void> _loadPlay() async {
    if (widget.sourceId.isEmpty || widget.sourceMid.isEmpty) {
      setState(() {
        _errorText = '缺少采集源播放参数';
        _loading = false;
      });
      return;
    }
    if (_name.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final info = await FilmApi.getPlayInfo(
        '',
        playFrom: widget.sourceId,
        episode: _episodeIndex,
        sid: widget.sourceMid,
      );
      if (!mounted) return;
      final detail = info.detail;
      setState(() {
        _name = detail.name;
        _picture = detail.picture;
        _plot = detail.descriptor.content.isNotEmpty ? detail.descriptor.content : detail.descriptor.blurb;
        _sources = detail.list;
        _playingSourceId = info.currentPlayFrom.isNotEmpty
            ? info.currentPlayFrom
            : (detail.list.isNotEmpty ? detail.list.first.id : '');
        _episodeIndex = info.currentEpisode;
        _playUrl = info.current.link;
        _playTitle = '${detail.name} · ${info.current.episode}';
        _sourceName = _findSource(_playingSourceId)?.name ?? '采集源';
        _errorText = '';
        _loading = false;
        _persistEnabled = true;
      });
      _persistHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_name.isEmpty) {
          _errorText = '$e';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      });
    }
  }

  PlaySource? _findSource(String id) {
    for (final source in _sources) {
      if (source.id == id) return source;
    }
    return _sources.isNotEmpty ? _sources.first : null;
  }

  void _selectEpisode(String sourceId, int index) {
    if (_playingSourceId == sourceId && _episodeIndex == index && _playUrl.isNotEmpty) return;
    final source = _findSource(sourceId);
    if (source == null || index < 0 || index >= source.linkList.length) return;
    final episode = source.linkList[index];
    setState(() {
      _playingSourceId = sourceId;
      _episodeIndex = index;
      _initialTime = 0;
      _lastCurrentTime = 0;
      _lastDuration = 0;
      _playUrl = episode.link;
      _playToken++;
      _playTitle = '$_name · ${episode.episode}';
      _sourceName = source.name;
    });
    _persistHistory(0, 0);
  }

  bool get _hasNext {
    final source = _findSource(_playingSourceId);
    return source != null && _episodeIndex < source.linkList.length - 1;
  }

  bool get _hasPrev => _episodeIndex > 0 && _findSource(_playingSourceId) != null;

  void _playPrev() {
    if (!_hasPrev) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已经是第一集了')));
      return;
    }
    _selectEpisode(_playingSourceId, _episodeIndex - 1);
  }

  void _playNext() {
    if (!_hasNext) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已经是最后一集了')));
      return;
    }
    _selectEpisode(_playingSourceId, _episodeIndex + 1);
  }

  void _persistHistory([double? currentTime, double? duration]) {
    if (!_persistEnabled || _historyId.isEmpty || _name.isEmpty) return;
    if (ServerConfigManager.instance.storageScope().isEmpty) return;
    final source = _findSource(_playingSourceId);
    final fallback = MovieUrlInfo(episode: _playTitle, link: _playUrl);
    final episode = (source != null && source.linkList.length > _episodeIndex)
        ? source.linkList[_episodeIndex]
        : fallback;
    HistoryManager.find(_historyId).then((prev) {
      HistoryManager.save(HistoryItem(
        id: _historyId,
        name: _name,
        picture: _picture,
        sourceId: widget.sourceId,
        sourceName: source?.name ?? _sourceName,
        episodeIndex: _episodeIndex,
        episode: episode.episode,
        currentTime: currentTime ?? (prev?.currentTime ?? 0),
        duration: duration ?? (prev?.duration ?? 0),
        timeStamp: DateTime.now().millisecondsSinceEpoch,
      ));
    });
  }

  void _setFullscreen(bool full, {bool isPortrait = false}) {
    if (_isFull == full) return;
    setState(() => _isFull = full);
    try {
      if (full) {
        SystemChrome.setPreferredOrientations(
          isPortrait
              ? [DeviceOrientation.portraitUp]
              : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
        );
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations(kAutoRotationOrientations);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } catch (_) {}
  }

  Widget _player({required bool isFull, required bool wide}) {
    final padding = MediaQuery.paddingOf(context);
    final player = VideoPlayerWidget(
      key: _videoKey,
      videoUrl: _playUrl,
      title: _playTitle,
      poster: ServerConfigManager.instance.resolveMediaUrl(_picture),
      initialTime: _initialTime,
      showBack: isFull,
      isFull: isFull,
      hasPrev: _hasPrev,
      hasNext: _hasNext,
      topInset: isFull ? padding.top : 0,
      bottomInset: isFull ? padding.bottom : 0,
      leftInset: isFull ? padding.left : 0,
      rightInset: isFull ? padding.right : 0,
      reloadToken: _playToken,
      onBack: () => _setFullscreen(false),
      onEnded: () {
        if (AppSettingsManager.instance.autoPlayNext && _hasNext) _playNext();
      },
      onPrev: _playPrev,
      onNext: _playNext,
      onFullscreenChange: _setFullscreen,
      onProgress: (cur, dur) {
        _lastCurrentTime = cur;
        _lastDuration = dur;
        _persistHistory(cur, dur);
      },
    );
    if (isFull) return Expanded(child: player);
    final box = AspectRatio(aspectRatio: 16 / 9, child: player);
    return wide ? Expanded(child: Center(child: box)) : box;
  }

  @override
  Widget build(BuildContext context) {
    if (_isPipActive && _playUrl.isNotEmpty) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox.expand(
            child: VideoPlayerWidget(
              key: _videoKey,
              videoUrl: _playUrl,
              title: _playTitle,
              showBack: false,
              isFull: false,
              reloadToken: _playToken,
              onFullscreenChange: _setFullscreen,
            ),
          ),
        ),
      );
    }

    final isFullMode = _isFull;
    final wide = Breakpoint.isWideWidth(MediaQuery.sizeOf(context).width);

    return PopScope(
      canPop: !isFullMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isFullMode) _setFullscreen(false);
      },
      child: Scaffold(
        backgroundColor: isFullMode ? Colors.black : AppTheme.bg,
        body: SafeArea(
          top: !isFullMode,
          bottom: !isFullMode,
          left: false,
          right: false,
          child: Column(
            children: [
              if (!isFullMode) PageHeader(title: _name.isNotEmpty ? _name : '现场播放'),
              if (_loading && _name.isEmpty)
                const Expanded(child: LoadingView(label: '正在打开播放页'))
              else if (_errorText.isNotEmpty && _name.isEmpty)
                Expanded(
                  child: EmptyState(
                    title: '当前内容无法播放',
                    subtitle: _errorText,
                    icon: Icons.play_disabled_rounded,
                  ),
                )
              else ...[
                if (_playUrl.isNotEmpty) _player(isFull: isFullMode, wide: wide),
                if (!isFullMode)
                  Expanded(
                    child: SingleChildScrollView(
                      child: LivePlayPanel(
                        sources: _sources,
                        playingSourceId: _playingSourceId,
                        episodeIndex: _episodeIndex,
                        plot: _plot,
                        onSelectEpisode: _selectEpisode,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
