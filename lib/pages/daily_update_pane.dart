import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../api/film_api.dart';
import '../components/film_card.dart';
import '../components/loading_view.dart';
import '../components/empty_state.dart';

const int _pageSize = 21;

/// 每日更新单分类面板组件
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

class _DailyUpdatePaneState extends State<DailyUpdatePane> {
  List<MovieBasicInfo> _list = [];
  PageInfo _page = PageInfo(pageSize: _pageSize, current: 1, pageCount: 1, total: 0);
  bool _loading = true;
  bool _loadingMore = false;
  String _errorText = '';
  final ScrollController _scrollController = ScrollController();
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.seedList != null && widget.seedList!.isNotEmpty && widget.pid == 0) {
      _list = widget.seedList!;
      _page = widget.seedPage ?? _page;
      _loading = false;
      _hasLoaded = true;
    } else if (widget.active) {
      _loadData(true);
    }
  }

  @override
  void didUpdateWidget(covariant DailyUpdatePane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_hasLoaded) {
      _loadData(true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _page.current < _page.pageCount) {
        _loadData(false);
      }
    }
  }

  Future<void> _loadData(bool reset) async {
    final nextPage = reset ? 1 : _page.current + 1;
    if (!reset && (_loadingMore || nextPage > _page.pageCount)) return;

    if (reset) {
      if (_list.isEmpty) {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (reset && _list.isEmpty) {
          _errorText = '$e';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _list.isEmpty) {
      return const LoadingView(label: '正在加载今日更新');
    }

    if (_errorText.isNotEmpty && _list.isEmpty) {
      return EmptyState(
        title: '加载失败',
        subtitle: _errorText,
        icon: Icons.error_outline_rounded,
        action: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.bgCard,
            foregroundColor: AppTheme.textPrimary,
          ),
          onPressed: () => _loadData(true),
          child: const Text('重试'),
        ),
      );
    }

    if (_list.isEmpty) {
      return const EmptyState(
        title: '暂无更新',
        subtitle: '今日暂无更新内容',
        icon: Icons.calendar_today_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(true),
      color: AppTheme.accent,
      backgroundColor: AppTheme.bgCard,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.54,
                crossAxisSpacing: AppTheme.spaceSm,
                mainAxisSpacing: AppTheme.spaceMd,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return FilmCard(film: _list[index]);
                },
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
                      : (_page.current >= _page.pageCount ? '没有更多了' : '滑动加载更多'),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
