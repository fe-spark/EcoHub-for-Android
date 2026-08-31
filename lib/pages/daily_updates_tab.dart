import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../api/film_api.dart';
import '../utils/source_guard.dart';
import '../components/loading_view.dart';
import '../components/empty_state.dart';
import 'daily_update_pane.dart';

const int _pageSize = 21;

/// 每日更新 Tab 页面
class DailyUpdatesTab extends StatefulWidget {
  const DailyUpdatesTab({super.key});

  @override
  State<DailyUpdatesTab> createState() => _DailyUpdatesTabState();
}

class _DailyUpdatesTabState extends State<DailyUpdatesTab> with SingleTickerProviderStateMixin {
  List<DailyUpdateCategory> _categories = [];
  int _currentIndex = 0;
  bool _loading = true;
  String _errorText = '';
  List<MovieBasicInfo> _seedList = [];
  PageInfo _seedPage = PageInfo(pageSize: _pageSize, current: 1, pageCount: 1, total: 0);
  TabController? _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    SourceGuard.onReconnect(_onReconnect);
    _loadMeta();
  }

  @override
  void dispose() {
    SourceGuard.offReconnect(_onReconnect);
    _tabController?.dispose();
    super.dispose();
  }

  void _onReconnect() {
    _loadMeta();
  }

  Future<void> _handleRefresh() async {
    if (_loading) return;
    setState(() {
      _currentIndex = 0;
      _categories = [];
      _seedList = [];
      _refreshKey++;
    });
    _tabController?.dispose();
    _tabController = null;
    await _loadMeta();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loading = true;
      _errorText = '';
    });

    try {
      final result = await FilmApi.getDailyUpdates(0, 1, pageSize: _pageSize);
      var cats = result.categories;
      if (cats.isEmpty) {
        cats = [DailyUpdateCategory(pid: 0, name: '全部', count: result.page.total)];
      }

      if (!mounted) return;

      _tabController?.dispose();
      _tabController = TabController(length: cats.length, vsync: this);
      _tabController!.animation?.addListener(() {
        final animIndex = _tabController!.animation!.value.round();
        if (_currentIndex != animIndex) {
          setState(() {
            _currentIndex = animIndex;
          });
        }
      });
      _tabController!.addListener(() {
        if (_currentIndex != _tabController!.index) {
          setState(() {
            _currentIndex = _tabController!.index;
          });
        }
      });

      setState(() {
        _categories = cats;
        _seedList = result.list;
        _seedPage = result.page;
        _loading = false;
        _currentIndex = 0;
        _errorText = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = '$e';
      });
    }
  }

  DailyUpdateCategory _currentCategory() {
    if (_currentIndex >= 0 && _currentIndex < _categories.length) {
      return _categories[_currentIndex];
    }
    return DailyUpdateCategory(pid: 0, name: '全部', count: 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    if (_loading && _categories.isEmpty) {
      bodyContent = const Expanded(
        child: LoadingView(label: '正在加载今日更新'),
      );
    } else if (_errorText.isNotEmpty && _categories.isEmpty) {
      bodyContent = Expanded(
        child: EmptyState(
          title: '加载失败',
          subtitle: _errorText,
          icon: Icons.error_outline_rounded,
          action: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bgCard,
              foregroundColor: AppTheme.textPrimary,
            ),
            onPressed: _loadMeta,
            child: const Text('重试'),
          ),
        ),
      );
    } else {
      bodyContent = Expanded(
        child: Column(
          children: [
            // Categories TabBar
            if (_categories.length > 1 && _tabController != null)
              Container(
                height: 32,
                margin: const EdgeInsets.only(top: 2, bottom: 6),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  tabs: List.generate(_categories.length, (index) {
                    final cat = _categories[index];
                    final active = _currentIndex == index;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // TabBarView
            Expanded(
              child: _tabController != null
                  ? TabBarView(
                      key: ValueKey('daily_tabbar_view_$_refreshKey'),
                      controller: _tabController,
                      children: List.generate(_categories.length, (index) {
                        final cat = _categories[index];
                        return DailyUpdatePane(
                          key: ValueKey('daily_pane_${cat.pid}_$_refreshKey'),
                          pid: cat.pid,
                          active: (index - _currentIndex).abs() <= 1,
                          seedList: cat.pid == 0 ? _seedList : null,
                          seedPage: cat.pid == 0 ? _seedPage : null,
                        );
                      }),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    '每日更新',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_categories.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        children: [
                          const TextSpan(text: '近 24 小时 '),
                          TextSpan(
                            text: '${_currentCategory().count}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent,
                            ),
                          ),
                          const TextSpan(text: ' 部'),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                      tooltip: '重新获取',
                      onPressed: _loading ? null : _handleRefresh,
                    ),
                  ),
                ],
              ),
            ),

            // Main Body Content
            bodyContent,
          ],
        ),
      ),
    );
  }
}
