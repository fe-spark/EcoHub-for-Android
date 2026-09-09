import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../api/film_api.dart';
import '../api/http_client.dart';
import '../utils/history_manager.dart';
import '../utils/play_resume.dart';
import '../utils/server_config_manager.dart';
import '../utils/source_guard.dart';
import '../utils/format_util.dart';
import '../components/player/video_player_widget.dart';
import '../components/player/play_detail_panel.dart';
import '../components/film_grid.dart';
import '../components/loading_view.dart';
import '../components/empty_state.dart';

/// 影片播放主页面
class PlayPage extends StatefulWidget {
  final String id;
  final String sourceId;
  final int episodeIndex;
  final double currentTime;

  const PlayPage({
    super.key,
    required this.id,
    this.sourceId = '',
    this.episodeIndex = 0,
    this.currentTime = 0,
  });

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> with WidgetsBindingObserver {
  late String _filmId;
  bool _loading = true;
  String _errorText = '';
  String _name = '';
  String _picture = '';
  String _subTitle = '';
  String _actor = '';
  String _plot = '';
  MovieDescriptor? _descriptor;
  List<PlaySource> _sources = [];
  String _playingSourceId = '';
  String _viewingSourceId = '';
  int _episodeIndex = 0;
  String _playUrl = '';
  int _playToken = 0;
  String _playTitle = '';
  double _initialTime = 0;
  List<MovieBasicInfo> _related = [];
  bool _relateLoading = false;
  int _activeTab = 0;
  bool _playerFull = false;
  String _sourceName = '默认源';
  double _lastCurrentTime = 0;
  double _lastDuration = 0;
  bool _persistEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _filmId = widget.id;
    _episodeIndex = widget.episodeIndex;
    _initialTime = widget.currentTime;
    _lastCurrentTime = _initialTime;
    HttpClient.instance.trackView('play', _filmId, 'PlayPage');
    SourceGuard.onReconnect(_onReconnect);

    _initPlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_lastCurrentTime > 0) {
      _persistHistory(_lastCurrentTime, _lastDuration);
    }
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}
    SourceGuard.offReconnect(_onReconnect);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_lastCurrentTime > 0) {
        _persistHistory(_lastCurrentTime, _lastDuration);
      }
    }
  }

  void _onReconnect() {
    _persistEnabled = false;
    _loadPlay(_playingSourceId);
    _loadRelate();
  }

  Future<void> _initPlay() async {
    var sid = widget.sourceId;
    if (sid.isEmpty && widget.episodeIndex == 0 && widget.currentTime == 0 && _filmId.isNotEmpty) {
      final resume = await PlayResume.fromHistory(_filmId);
      sid = resume.sourceId;
      _episodeIndex = resume.episodeIndex;
      _initialTime = resume.currentTime;
      _lastCurrentTime = resume.currentTime;
      _lastDuration = resume.duration;
    }
    _loadPlay(sid);
    _loadRelate();
  }

  Future<void> _loadPlay(String sourceId) async {
    if (_filmId.isEmpty) {
      setState(() {
        _errorText = '未找到影片参数';
        _loading = false;
      });
      return;
    }

    if (_name.isEmpty) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final info = await FilmApi.getPlayInfo(_filmId, playFrom: sourceId, episode: _episodeIndex);
      if (!mounted) return;

      final detail = info.detail;
      setState(() {
        _name = detail.name;
        _picture = detail.picture;
        _descriptor = detail.descriptor;
        _subTitle = detail.descriptor.subTitle;
        _actor = detail.descriptor.actor;
        _plot = detail.descriptor.content.isNotEmpty ? detail.descriptor.content : detail.descriptor.blurb;
        _sources = detail.list;
        _playingSourceId = info.currentPlayFrom.isNotEmpty
            ? info.currentPlayFrom
            : (detail.list.isNotEmpty ? detail.list.first.id : '');
        _viewingSourceId = _playingSourceId;
        _episodeIndex = info.currentEpisode;
        _playUrl = info.current.link;
        _playTitle = '${detail.name} · ${info.current.episode}';
        _sourceName = _findSource(_playingSourceId)?.name ?? '默认源';
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

  Future<void> _loadRelate() async {
    if (_filmId.isEmpty) return;
    setState(() {
      _relateLoading = true;
    });
    try {
      final list = await FilmApi.getRelate(_filmId);
      if (!mounted) return;
      setState(() {
        _related = list;
        _relateLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _related = [];
        _relateLoading = false;
      });
    }
  }

  PlaySource? _findSource(String id) {
    for (final s in _sources) {
      if (s.id == id) return s;
    }
    return _sources.isNotEmpty ? _sources.first : null;
  }

  void _selectEpisode(String sourceId, int index) {
    final source = _findSource(sourceId);
    if (source == null || index < 0 || index >= source.linkList.length) return;
    final ep = source.linkList[index];

    setState(() {
      _playingSourceId = sourceId;
      _viewingSourceId = sourceId;
      _episodeIndex = index;
      _initialTime = 0;
      _lastCurrentTime = 0;
      _lastDuration = 0;
      _playUrl = ep.link;
      _playToken++;
      _playTitle = '$_name · ${ep.episode}';
      _sourceName = source.name;
    });
    _persistHistory(0, 0);
  }

  bool _hasNext() {
    final source = _findSource(_playingSourceId);
    if (source == null) return false;
    return _episodeIndex < source.linkList.length - 1;
  }

  bool _hasPrev() {
    return _episodeIndex > 0 && _findSource(_playingSourceId) != null;
  }

  void _playPrev() {
    if (!_hasPrev()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已经是第一集了')));
      return;
    }
    _selectEpisode(_playingSourceId, _episodeIndex - 1);
  }

  void _playNext() {
    if (!_hasNext()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已经是最后一集了')));
      return;
    }
    _selectEpisode(_playingSourceId, _episodeIndex + 1);
  }

  void _persistHistory([double? currentTime, double? duration]) {
    if (!_persistEnabled || _filmId.isEmpty || _name.isEmpty) return;
    if (ServerConfigManager.instance.storageScope().isEmpty) return;

    final source = _findSource(_playingSourceId);
    final sourceName = source != null ? source.name : _sourceName;
    final fallback = MovieUrlInfo(episode: _playTitle, link: _playUrl);
    final ep = (source != null && source.linkList.length > _episodeIndex)
        ? source.linkList[_episodeIndex]
        : fallback;

    HistoryManager.find(_filmId).then((prev) {
      final cur = currentTime ?? (prev?.currentTime ?? 0);
      final dur = duration ?? (prev?.duration ?? 0);
      final item = HistoryItem(
        id: _filmId,
        name: _name,
        picture: _picture,
        sourceId: _playingSourceId,
        sourceName: sourceName,
        episodeIndex: _episodeIndex,
        episode: ep.episode,
        currentTime: cur,
        duration: dur,
        timeStamp: DateTime.now().millisecondsSinceEpoch,
      );
      HistoryManager.save(item);
    });
  }

  Future<void> _openRelated(MovieBasicInfo film) async {
    final id = FormatUtil.filmId(film);
    if (id.isEmpty || id == _filmId) return;

    _filmId = id;
    HttpClient.instance.trackView('play', _filmId, 'PlayPage');
    final resume = await PlayResume.fromHistory(_filmId);
    if (!mounted) return;
    setState(() {
      _name = '';
      _sources = [];
      _playUrl = '';
      _loading = true;
      _episodeIndex = resume.episodeIndex;
      _initialTime = resume.currentTime;
      _lastCurrentTime = resume.currentTime;
      _lastDuration = resume.duration;
      _activeTab = 0;
    });
    _loadPlay(resume.sourceId);
    _loadRelate();
  }

  void _setFullscreen(bool full, {bool isPortrait = false}) {
    if (_playerFull == full) return;
    setState(() => _playerFull = full);
    try {
      if (full) {
        SystemChrome.setPreferredOrientations(isPortrait
            ? [DeviceOrientation.portraitUp]
            : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } catch (_) {}
  }

  Widget _buildVideoPlayer({required bool isFull}) {
    return VideoPlayerWidget(
      key: const ValueKey('play_page_video_player'),
      videoUrl: _playUrl,
      reloadToken: _playToken,
      title: _playTitle,
      poster: ServerConfigManager.instance.resolveMediaUrl(_picture),
      initialTime: _initialTime,
      showBack: true,
      isFull: isFull,
      hasPrev: _hasPrev(),
      hasNext: _hasNext(),
      onBack: () {
        if (_playerFull) {
          _setFullscreen(false);
        } else {
          Navigator.pop(context);
        }
      },
      onEnded: () {
        if (_hasNext()) _playNext();
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
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isFullMode = _playerFull || isLandscape;

    return PopScope(
      canPop: !isFullMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isFullMode) {
          _setFullscreen(false);
        }
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
              // Player Layer
              if (isFullMode)
                Expanded(
                  child: _buildVideoPlayer(isFull: true),
                )
              else if (_loading && _name.isEmpty)
                const Expanded(child: LoadingView(label: '正在打开播放页'))
              else if (_errorText.isNotEmpty && _name.isEmpty)
                Expanded(
                  child: EmptyState(
                    title: '当前内容无法播放',
                    subtitle: _errorText,
                    icon: Icons.play_disabled_rounded,
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildVideoPlayer(isFull: false),
                ),

              // Below Player (Tabs & Panels)
              if (!isFullMode && !_loading && _name.isNotEmpty) ...[
                Container(height: 8, color: AppTheme.bgElevated),

                // Tab Switcher
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                  child: Row(
                    children: [
                      _buildTabItem('详情', 0),
                      _buildTabItem('相关推荐', 1),
                    ],
                  ),
                ),

                // Tab Contents
                Expanded(
                  child: _activeTab == 0
                      ? PlayDetailPanel(
                          filmId: _filmId,
                          picture: _picture,
                          name: _name,
                          subTitle: _subTitle,
                          actor: _actor,
                          plot: _plot,
                          descriptor: _descriptor,
                          sources: _sources,
                          playingSourceId: _playingSourceId,
                          viewingSourceId: _viewingSourceId,
                          episodeIndex: _episodeIndex,
                          onViewSource: (id) {
                            setState(() {
                              _viewingSourceId = id;
                            });
                          },
                          onSelectEpisode: (sourceId, index) {
                            _selectEpisode(sourceId, index);
                          },
                        )
                      : _buildRelatedTab(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: active ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 18,
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedTab() {
    if (_relateLoading) {
      return const LoadingView(label: '加载相关推荐');
    }
    if (_related.isEmpty) {
      return const EmptyState(
        title: '暂无相关推荐',
        subtitle: '换一部片子再看看',
        icon: Icons.movie_outlined,
      );
    }
    return FilmGrid(
      films: _related,
      columns: 3,
      onClickFilm: _openRelated,
    );
  }
}
