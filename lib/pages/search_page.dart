import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../api/film_api.dart';
import '../api/http_client.dart';
import '../utils/search_history_manager.dart';
import '../utils/source_guard.dart';
import '../utils/breakpoint.dart';
import '../components/search_result_item.dart';
import '../components/loading_view.dart';
import '../components/empty_state.dart';

const List<String> _defaultHotKeywords = [
  '凡人修仙传', '庆余年', '仙逆', '吞噬星空', '遮天', '斗破苍穹', '白夜破晓', '大奉打更人'
];

/// 影片搜索页面
class SearchPage extends StatefulWidget {
  final String initialKeyword;

  const SearchPage({super.key, this.initialKeyword = ''});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _submitted = '';
  List<MovieBasicInfo> _list = [];
  PageInfo _page = PageInfo(pageSize: 10, current: 1, pageCount: 0, total: 0);
  bool _loading = false;
  bool _loadingMore = false;
  List<String> _searchHistory = [];
  List<String> _hotKeywords = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadHotKeywords();
    SourceGuard.onReconnect(_onReconnect);
    _scrollController.addListener(_onScroll);

    if (widget.initialKeyword.isNotEmpty) {
      _inputController.text = widget.initialKeyword;
      _doSearch(true);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _submitted.isEmpty) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    SourceGuard.offReconnect(_onReconnect);
    super.dispose();
  }

  void _onReconnect() {
    _loadHistory();
    _loadHotKeywords();
    if (_submitted.isNotEmpty) {
      _doSearch(true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _page.current < _page.pageCount) {
        _doSearch(false);
      }
    }
  }

  Future<void> _loadHistory() async {
    final list = await SearchHistoryManager.list();
    if (mounted) {
      setState(() {
        _searchHistory = list;
      });
    }
  }

  Future<void> _loadHotKeywords() async {
    try {
      final list = await FilmApi.getHotKeywords();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _hotKeywords = list;
        });
        return;
      }
    } catch (_) {}
    if (mounted && _hotKeywords.isEmpty) {
      setState(() {
        _hotKeywords = List.from(_defaultHotKeywords);
      });
    }
  }

  String _getSearchPlaceholder() {
    if (_hotKeywords.isNotEmpty) {
      return '大家都在搜：${_hotKeywords.first}';
    }
    return '搜索电影、剧集、动漫';
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: const Text('清空搜索历史', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: const Text('确定要清空全部搜索记录吗？', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('取消', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await SearchHistoryManager.clear();
              await _loadHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已清空搜索历史')),
                );
              }
            },
            child: const Text('清空', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _doSearch(bool reset) async {
    final kw = _inputController.text.trim();
    if (kw.isEmpty) {
      if (reset) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入搜索关键词')),
        );
      }
      return;
    }

    final nextPage = reset ? 1 : _page.current + 1;
    if (!reset && nextPage > _page.pageCount) return;

    _focusNode.unfocus();

    if (reset) {
      HttpClient.instance.trackView('search', kw, 'SearchPage');
      setState(() {
        _loading = true;
        _list = [];
      });
      SearchHistoryManager.add(kw).then((_) => _loadHistory());
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    try {
      final res = await FilmApi.searchFilm(kw, current: nextPage);
      if (!mounted) return;
      setState(() {
        _submitted = kw;
        _page = res.page;
        _list = reset ? res.list : [..._list, ...res.list];
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              focusNode: _focusNode,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText: _getSearchPlaceholder(),
                                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _doSearch(true),
                              onChanged: (val) {
                                if (val.trim().isEmpty && _submitted.isNotEmpty) {
                                  setState(() {
                                    _submitted = '';
                                    _list = [];
                                  });
                                }
                              },
                            ),
                          ),
                          if (_inputController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _inputController.clear();
                                  _submitted = '';
                                  _list = [];
                                });
                              },
                              child: const Icon(Icons.cancel_rounded, size: 18, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _doSearch(true),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            // Body Area
            Expanded(
              child: _loading
                  ? const LoadingView(label: '正在搜索')
                  : _submitted.isEmpty
                      ? _buildHistoryAndHot()
                      : _buildResultList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryAndHot() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg, vertical: AppTheme.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search History Section
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                GestureDetector(
                  onTap: _confirmClearHistory,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.textMuted),
                      SizedBox(width: 2),
                      Text('清空', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((item) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          _inputController.text = item;
                          _doSearch(true);
                        },
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppTheme.radiusPill)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          SearchHistoryManager.remove(item).then((_) => _loadHistory());
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8, left: 2),
                          child: Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Hot Search Section
          if (_hotKeywords.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.local_fire_department_rounded, size: 16, color: AppTheme.accent),
                SizedBox(width: 4),
                Text(
                  '热门搜索',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_hotKeywords.length, (index) {
                final item = _hotKeywords[index];
                final isTop3 = index < 3;
                return InkWell(
                  onTap: () {
                    _inputController.text = item;
                    _doSearch(true);
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isTop3 ? AppTheme.bgChip : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(
                        color: isTop3 ? AppTheme.accentSoft : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isTop3 ? AppTheme.accent : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_list.isEmpty) {
      return EmptyState(
        title: '没有结果',
        subtitle: '未找到与「$_submitted」相关的影片',
        icon: Icons.search_off_rounded,
      );
    }

    final lanes = Breakpoint.listLanesOf(MediaQuery.sizeOf(context).width);

    return RefreshIndicator(
      onRefresh: () => _doSearch(true),
      color: AppTheme.accent,
      backgroundColor: AppTheme.bgCard,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceLg, 8, AppTheme.spaceLg, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                '共 ${_page.total} 部与「$_submitted」相关',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          ),
          if (lanes <= 1)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SearchResultItem(film: _list[index]),
                  ),
                  childCount: _list.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: lanes,
                  mainAxisExtent: 148,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SearchResultItem(film: _list[index]),
                  childCount: _list.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
