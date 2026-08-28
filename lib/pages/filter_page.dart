import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../api/film_api.dart';
import '../api/http_client.dart';
import '../utils/source_guard.dart';
import '../components/filter_tag_row.dart';
import '../components/film_card.dart';
import '../components/loading_view.dart';
import '../components/empty_state.dart';
import '../components/scroll_fab.dart';

const int _pageSize = 21;

/// 片库分类筛选页面
class FilterPage extends StatefulWidget {
  final String pid;
  final String category;
  final String sort;

  const FilterPage({
    super.key,
    required this.pid,
    this.category = '',
    this.sort = '',
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String _pid = '';
  String _titleName = '片库';
  List<MovieBasicInfo> _films = [];
  int _total = 0;
  int _current = 1;
  int _pageCount = 1;
  bool _loading = true;
  bool _listLoading = false;
  bool _loadingMore = false;
  String _errorText = '';

  List<String> _sortList = [];
  List<String> _titleKeys = [];
  List<String> _titles = [];
  List<String> _tagKeys = [];
  List<List<String>> _tagNames = [];
  List<List<String>> _tagValues = [];

  final Map<String, String> _selected = {};
  final ScrollController _scrollController = ScrollController();
  bool _showTopFab = false;

  @override
  void initState() {
    super.initState();
    _pid = widget.pid;
    HttpClient.instance.trackView('classify', _pid);
    if (widget.category.isNotEmpty) {
      _selected['Category'] = widget.category;
    }
    if (widget.sort.isNotEmpty) {
      _selected['Sort'] = widget.sort;
    }
    _scrollController.addListener(_onScroll);
    SourceGuard.onReconnect(_onReconnect);
    _loadData(true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    SourceGuard.offReconnect(_onReconnect);
    super.dispose();
  }

  void _onReconnect() {
    _loadData(true);
  }

  void _onScroll() {
    final y = _scrollController.offset;
    final showFab = y > 400;
    if (showFab != _showTopFab) {
      setState(() {
        _showTopFab = showFab;
      });
    }

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _current < _pageCount) {
        _loadData(false);
      }
    }
  }

  Map<String, dynamic> _buildQuery(int page) {
    final query = <String, dynamic>{
      'Pid': _pid,
      'current': page,
      'pageSize': _pageSize,
    };
    _selected.forEach((k, v) {
      if (v.isNotEmpty) {
        query[k] = v;
      }
    });
    return query;
  }

  void _pick(String key, String value) {
    if (_selected[key] == value) return;
    setState(() {
      _selected[key] = value;
    });
    _loadData(true);
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _loadData(bool reset) async {
    if (_pid.isEmpty) {
      setState(() {
        _errorText = '缺少分类信息';
        _loading = false;
      });
      return;
    }

    final page = reset ? 1 : _current + 1;
    if (!reset && (_loadingMore || page > _pageCount)) return;

    if (reset) {
      if (_sortList.isEmpty) {
        setState(() {
          _loading = true;
        });
      } else {
        setState(() {
          _listLoading = true;
        });
      }
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    try {
      final res = await FilmApi.getFilter(_buildQuery(page));
      if (!mounted) return;

      setState(() {
        _titleName = res.titleName.isNotEmpty ? res.titleName : '片库';
        _total = res.page.total;
        _current = res.page.current;
        _pageCount = res.page.pageCount;
        _films = reset ? res.list : [..._films, ...res.list];
        _sortList = res.search.sortList;
        _titleKeys = res.search.titleKeys;
        _titles = res.search.titles;
        _tagKeys = res.search.tagKeys;
        _tagNames = res.search.tagNames;
        _tagValues = res.search.tagValues;

        if (reset) {
          for (var i = 0; i < res.paramKeys.length; i++) {
            final k = res.paramKeys[i];
            final v = i < res.params.length ? res.params[i] : '';
            if (v.isNotEmpty && !_selected.containsKey(k)) {
              _selected[k] = v;
            }
          }
        }

        _loading = false;
        _listLoading = false;
        _loadingMore = false;
        _errorText = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _listLoading = false;
        _loadingMore = false;
        if (reset) {
          _errorText = '$e';
        }
      });
    }
  }

  String _titleOf(String key) {
    final index = _titleKeys.indexOf(key);
    return index >= 0 ? _titles[index] : key;
  }

  List<String> _namesOf(String key) {
    final index = _tagKeys.indexOf(key);
    return index >= 0 ? _tagNames[index] : [];
  }

  List<String> _valuesOf(String key) {
    final index = _tagKeys.indexOf(key);
    return index >= 0 ? _tagValues[index] : [];
  }

  String _labelOf(String key, String value) {
    if (value.isEmpty) return '';
    final values = _valuesOf(key);
    final names = _namesOf(key);
    final index = values.indexOf(value);
    if (index >= 0 && index < names.length) {
      return names[index];
    }
    return value;
  }

  List<String> _activeFilterKeys() {
    final keys = <String>[];
    for (final key in _sortList) {
      final val = _selected[key] ?? '';
      final label = _labelOf(key, val);
      if (label.isNotEmpty && label != '全部') {
        keys.add(key);
      }
    }
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final activeKeys = _activeFilterKeys();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: Text(
          _titleName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceLg),
              child: Center(
                child: Text(
                  '共 $_total 部',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const LoadingView(label: '正在加载筛选')
          else
            RefreshIndicator(
              onRefresh: () => _loadData(true),
              color: AppTheme.accent,
              backgroundColor: AppTheme.bgCard,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Filter Tags Container
                  if (_sortList.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                        color: AppTheme.bgElevated,
                        child: Column(
                          children: _sortList.map((key) {
                            return FilterTagRow(
                              filterKey: key,
                              title: _titleOf(key),
                              names: _namesOf(key),
                              values: _valuesOf(key),
                              selected: _selected[key] ?? '',
                              onPick: _pick,
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  // Active Filter Pills
                  if (activeKeys.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: 6),
                        child: Row(
                          children: activeKeys.map((key) {
                            final label = _labelOf(key, _selected[key] ?? '');
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentSoft,
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                border: Border.all(color: AppTheme.accent),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  // Film Grid / Loading / Empty
                  if (_listLoading)
                    const SliverFillRemaining(
                      child: LoadingView(label: '列表加载中'),
                    )
                  else if (_errorText.isNotEmpty)
                    SliverFillRemaining(
                      child: EmptyState(
                        title: '加载失败',
                        subtitle: _errorText,
                        icon: Icons.error_outline_rounded,
                        action: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bgCard),
                          onPressed: () => _loadData(true),
                          child: const Text('重试'),
                        ),
                      ),
                    )
                  else if (_films.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        title: '没有符合条件的影片',
                        subtitle: '请尝试更换其他筛选条件',
                        icon: Icons.movie_filter_outlined,
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: 8),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.54,
                          crossAxisSpacing: AppTheme.spaceSm,
                          mainAxisSpacing: AppTheme.spaceMd,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return FilmCard(film: _films[index]);
                          },
                          childCount: _films.length,
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
                                : (_current >= _pageCount ? '没有更多了' : '滑动加载更多'),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Scroll to top FAB
          Positioned(
            right: 16,
            bottom: 24,
            child: ScrollFab(
              visible: _showTopFab,
              onClickFab: _scrollToTop,
            ),
          ),
        ],
      ),
    );
  }
}
