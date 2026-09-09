import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../api/film_api.dart';
import '../components/film_card.dart';
import '../components/loading_view.dart';
import '../components/empty_state.dart';
import '../components/scroll_fab.dart';
import '../utils/breakpoint.dart';

const int _pageSize = 21;

/// 每日更新单分类面板，对齐 OHOS `DailyUpdatePane.ets`
class DailyUpdatePane extends StatefulWidget {
  final int pid;
  final bool active;
  final List<MovieBasicInfo>? seedList;
  final PageInfo? seedPage;

  const DailyUpdatePane({
    super.key,
    required this.pid,
    this.active = true,
    this.seedList,
    this.seedPage,
  });

  @override
  State<DailyUpdatePane> createState() => _DailyUpdatePaneState();
}

class _DailyUpdatePaneState extends State<DailyUpdatePane> with AutomaticKeepAliveClientMixin {
  List<MovieBasicInfo> _list = [];
  PageInfo _page = PageInfo(pageSize: _pageSize, current: 1, pageCount: 1, total: 0);
  bool _loading = true;
  bool _loadingMore = false;
  bool _fetchLock = false;
  String _errorText = '';
  final ScrollController _scrollController = ScrollController();
  bool _hasLoaded = false;
  bool _showTopFab = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.seedList != null && widget.pid == 0) {
      _list = widget.seedList!;
      _page = widget.seedPage ?? _page;
      _loading = false;
      _hasLoaded = true;
    } else if (widget.active) {
      _loadData(true, fromPull: false);
    }
  }

  @override
  void didUpdateWidget(covariant DailyUpdatePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_hasLoaded) {
      _loadData(true, fromPull: false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 1400)),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      if (!_loadingMore && _page.current < _page.pageCount) {
        _loadData(false, fromPull: false);
      }
    }
    final show = pos.viewportDimension > 0 && pos.pixels > pos.viewportDimension;
    if (show != _showTopFab) {
      setState(() {
        _showTopFab = show;
      });
    }
  }

  Future<void> _loadData(bool reset, {required bool fromPull}) async {
    if (_fetchLock) return;
    final nextPage = reset ? 1 : _page.current + 1;
    if (!reset && (_loadingMore || nextPage > _page.pageCount)) return;

    _fetchLock = true;
    if (reset) {
      if (!fromPull && _list.isEmpty) {
        setState(() {
          _loading = true;
          _errorText = '';
        });
      }
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    var ok = false;
    try {
      final res = await FilmApi.getDailyUpdates(widget.pid, nextPage, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _list = reset ? res.list : [..._list, ...res.list];
        _page = res.page;
        _loading = false;
        _loadingMore = false;
        _hasLoaded = true;
        _errorText = '';
      });
      ok = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset && _list.isEmpty) {
          _errorText = '$e';
        } else if (!reset) {
          _toast('$e');
        }
      });
    } finally {
      _fetchLock = false;
    }
    if (fromPull) {
      if (ok) {
        _toast('已更新');
      } else {
        _toast(_errorText.isNotEmpty ? _errorText : '刷新失败');
      }
    }
  }

  Widget _refreshable({required Widget child}) {
    return RefreshIndicator(
      onRefresh: () => _loadData(true, fromPull: true),
      color: AppTheme.accent,
      backgroundColor: AppTheme.bgCard,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _list.isEmpty) {
      return const LoadingView(label: '正在加载今日更新');
    }

    if (_errorText.isNotEmpty && _list.isEmpty) {
      return _refreshable(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 48),
            EmptyState(
              title: '加载失败',
              subtitle: _errorText,
              icon: Icons.error_outline_rounded,
              action: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.bgCard,
                  foregroundColor: AppTheme.textPrimary,
                ),
                onPressed: () => _loadData(true, fromPull: false),
                child: const Text('重试'),
              ),
            ),
          ],
        ),
      );
    }

    if (_list.isEmpty) {
      return _refreshable(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 48),
            EmptyState(
              title: '暂无更新',
              subtitle: '近 24 小时还没有新片入库',
              icon: Icons.local_fire_department_rounded,
            ),
          ],
        ),
      );
    }

    final cols = Breakpoint.gridColsOf(MediaQuery.sizeOf(context).width);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        _refreshable(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg, vertical: AppTheme.spaceSm),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 0.54,
                    crossAxisSpacing: AppTheme.spaceSm,
                    mainAxisSpacing: AppTheme.spaceMd,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FilmCard(film: _list[index]),
                    childCount: _list.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      _loadingMore
                          ? '加载中...'
                          : (_page.current >= _page.pageCount ? '没有更多了' : ''),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ScrollFab(
          visible: _showTopFab,
          onClickFab: () {
            setState(() => _showTopFab = false);
            _scrollController.animateTo(0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
          },
        ),
      ],
    );
  }
}
