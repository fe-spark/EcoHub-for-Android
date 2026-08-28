import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../utils/format_util.dart';
import '../utils/server_config_manager.dart';
import '../utils/source_guard.dart';
import '../api/film_api.dart';
import '../components/loading_view.dart';
import '../components/empty_state.dart';
import '../components/film_row.dart';

/// 首页推荐 Tab
class RecommendTab extends StatefulWidget {
  final String siteName;
  final VoidCallback? onOpenSearch;

  const RecommendTab({
    super.key,
    required this.siteName,
    this.onOpenSearch,
  });

  @override
  State<RecommendTab> createState() => _RecommendTabState();
}

class _RecommendTabState extends State<RecommendTab> {
  List<BannerItem> _banners = [];
  List<HomeSection> _sections = [];
  bool _loading = true;
  String _errorText = '';
  double _headerAlpha = 0.72;
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    SourceGuard.onReconnect(_onReconnect);
    _loadHome(false);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bannerController.dispose();
    SourceGuard.offReconnect(_onReconnect);
    super.dispose();
  }

  void _onReconnect() {
    _loadHome(false);
  }

  void _onScroll() {
    final y = _scrollController.offset;
    final ratio = (y / 160.0).clamp(0.0, 1.0);
    final alpha = 0.72 + (1.0 - 0.72) * ratio;
    if ((alpha - _headerAlpha).abs() >= 0.02) {
      setState(() {
        _headerAlpha = alpha;
      });
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_banners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 4800), (timer) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadHome(bool fromPull) async {
    if (!fromPull && _banners.isEmpty && _sections.isEmpty) {
      setState(() {
        _loading = true;
        _errorText = '';
      });
    }
    try {
      final home = await FilmApi.getHome();
      if (!mounted) return;
      setState(() {
        _banners = home.banners;
        _sections = home.content;
        _loading = false;
        _errorText = '';
      });
      _startBannerTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = '$e';
      });
    }
  }

  List<HomeSection> _visibleSections() {
    return _sections.where((s) => s.nav.show).toList();
  }

  Widget _buildHeroBanner(BannerItem item) {
    final backdrop = ServerConfigManager.instance.resolveMediaUrl(FormatUtil.bannerBackdrop(item));

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backdrop.isNotEmpty)
          CachedNetworkImage(
            imageUrl: backdrop,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(color: AppTheme.bgCard),
          )
        else
          Container(color: AppTheme.bgCard),

        // 黑色多段渐变
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x140A0B10),
                const Color(0x1F0A0B10),
                AppTheme.bg.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          left: AppTheme.spaceLg,
          right: AppTheme.spaceLg,
          bottom: AppTheme.spaceLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.remark.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    item.remark,
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                FormatUtil.joinMeta([item.year, item.cName, item.area]),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () {
                  final id = item.mid > 0 ? '${item.mid}' : item.id;
                  Navigator.pushNamed(context, '/play', arguments: {'id': id});
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('立即播放', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Main Body
        if (_loading)
          const LoadingView(label: '正在加载推荐')
        else if (_errorText.isNotEmpty)
          RefreshIndicator(
            onRefresh: () => _loadHome(true),
            color: AppTheme.accent,
            backgroundColor: AppTheme.bgCard,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                EmptyState(
                  title: '加载失败',
                  subtitle: _errorText,
                  icon: Icons.error_outline_rounded,
                  action: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.bgCard,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    onPressed: () => _loadHome(true),
                    child: const Text('重试'),
                  ),
                ),
              ],
            ),
          )
        else
          RefreshIndicator(
            onRefresh: () => _loadHome(true),
            color: AppTheme.accent,
            backgroundColor: AppTheme.bgCard,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Banner Carousel
                  if (_banners.isNotEmpty)
                    SizedBox(
                      height: 380 + topInset,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _bannerController,
                            itemCount: _banners.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return _buildHeroBanner(_banners[index]);
                            },
                          ),
                          if (_banners.length > 1)
                            Positioned(
                              bottom: 12,
                              right: AppTheme.spaceLg,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(_banners.length, (index) {
                                  final active = _currentBannerIndex == index;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                    width: active ? 12 : 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: active ? AppTheme.accent : Colors.white38,
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    SizedBox(height: 56 + topInset),

                  // Category Pills
                  if (_visibleSections().isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceLg, vertical: 8),
                      child: Text(
                        '片库分类',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                      child: Row(
                        children: _visibleSections().map((section) {
                          final bg = FormatUtil.tagBg(section.nav.id, section.nav.name);
                          final border = FormatUtil.tagBorder(section.nav.id, section.nav.name);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/filter', arguments: {'Pid': '${section.nav.id}'});
                              },
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                  border: Border.all(color: border),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  section.nav.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                  ],

                  // Film Rows for each section
                  ..._visibleSections().map((section) {
                    final movies = section.movies.isNotEmpty ? section.movies : section.hot;
                    return FilmRow(
                      title: section.nav.name,
                      films: movies,
                      pid: section.nav.id,
                      onMore: () {
                        Navigator.pushNamed(context, '/filter', arguments: {'Pid': '${section.nav.id}'});
                      },
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

        // Floating Top Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 48 + topInset,
            padding: EdgeInsets.only(
              top: topInset,
              left: AppTheme.spaceLg,
              right: AppTheme.spaceLg,
            ),
            color: AppTheme.bg.withValues(alpha: _headerAlpha),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.siteName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (widget.onOpenSearch != null) {
                      widget.onOpenSearch!();
                    } else {
                      Navigator.pushNamed(context, '/search');
                    }
                  },
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded, size: 16, color: AppTheme.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          '搜索',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
