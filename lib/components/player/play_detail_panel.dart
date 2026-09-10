import 'dart:math';
import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../models/film_models.dart';
import '../../utils/breakpoint.dart';
import 'film_detail_header.dart';

const int _groupSize = 100;
const int _epNameWideLen = 6;
const double _epRowHeight = 54.0;
const double _epMinHeight = 44.0;

/// 播放页选集与详情面板，全量对齐鸿蒙端 `PlayDetailPanel.ets`
class PlayDetailPanel extends StatefulWidget {
  final String filmId;
  final String picture;
  final String name;
  final String subTitle;
  final String actor;
  final String plot;
  final MovieDescriptor? descriptor;
  final List<PlaySource> sources;
  final String playingSourceId;
  final String viewingSourceId;
  final int episodeIndex;
  final ValueChanged<String>? onViewSource;
  final void Function(String sourceId, int index)? onSelectEpisode;

  const PlayDetailPanel({
    super.key,
    required this.filmId,
    this.picture = '',
    required this.name,
    this.subTitle = '',
    this.actor = '',
    this.plot = '',
    this.descriptor,
    required this.sources,
    required this.playingSourceId,
    required this.viewingSourceId,
    required this.episodeIndex,
    this.onViewSource,
    this.onSelectEpisode,
  });

  @override
  State<PlayDetailPanel> createState() => _PlayDetailPanelState();
}

class _PlayDetailPanelState extends State<PlayDetailPanel> {
  final Map<String, int> _groupIndexes = {};
  final ScrollController _listScroller = ScrollController();
  final ScrollController _groupScroller = ScrollController();
  final ScrollController _sourceScroller = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 156.0;

  @override
  void initState() {
    super.initState();
    _syncGroupFromPlayingEpisode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeader();
      _syncSourceBar(false);
      _checkReadyAndScroll(false);
    });
  }

  @override
  void didUpdateWidget(covariant PlayDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sources != widget.sources) {
      _syncGroupFromPlayingEpisode();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureHeader();
        _checkReadyAndScroll(false);
        _syncSourceBar(false);
      });
    } else if (oldWidget.viewingSourceId != widget.viewingSourceId) {
      _clampGroup(widget.viewingSourceId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureHeader();
        _checkReadyAndScroll(true);
        _syncSourceBar(true);
      });
    } else if (oldWidget.episodeIndex != widget.episodeIndex ||
        oldWidget.playingSourceId != widget.playingSourceId) {
      if (widget.viewingSourceId == widget.playingSourceId) {
        _setGroup(widget.viewingSourceId, widget.episodeIndex ~/ _groupSize, false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureHeader();
          _scrollToFocusedEpisode(true);
        });
      }
    }
  }

  @override
  void dispose() {
    _listScroller.dispose();
    _groupScroller.dispose();
    _sourceScroller.dispose();
    super.dispose();
  }

  void _measureHeader() {
    final ctx = _headerKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final h = box.size.height;
        if (h > 0 && (_headerHeight - h).abs() > 1) {
          _headerHeight = h;
        }
      }
    }
  }

  PlaySource? _findSource(String id) {
    for (final s in widget.sources) {
      if (s.id == id) return s;
    }
    return widget.sources.isNotEmpty ? widget.sources.first : null;
  }

  List<MovieUrlInfo> _episodeList() {
    final source = _findSource(widget.viewingSourceId);
    return source?.linkList ?? [];
  }

  int _groupOf(String sourceId) {
    return _groupIndexes[sourceId] ?? 0;
  }

  void _setGroup(String sourceId, int groupIndex, [bool scrollReset = true]) {
    if (sourceId.isEmpty) return;
    final count = _groupCount();
    final safe = count <= 0 ? 0 : groupIndex.clamp(0, count - 1);
    final oldGroup = _groupOf(sourceId);
    if (oldGroup == safe && _groupIndexes.containsKey(sourceId)) {
      if (scrollReset) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocusedEpisode(true));
      }
      return;
    }
    setState(() {
      _groupIndexes[sourceId] = safe;
    });
    if (scrollReset) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocusedEpisode(true));
    }
  }

  void _clampGroup(String sourceId) {
    _setGroup(sourceId, _groupOf(sourceId), false);
  }

  void _syncGroupFromPlayingEpisode() {
    if (widget.viewingSourceId.isEmpty && widget.playingSourceId.isNotEmpty) {
      // Handled by parent view
    }
    if (widget.viewingSourceId == widget.playingSourceId) {
      final targetGroup = widget.episodeIndex ~/ _groupSize;
      _setGroup(widget.viewingSourceId, targetGroup, false);
    } else {
      _clampGroup(widget.viewingSourceId);
    }
  }

  int _groupCount() {
    final total = _episodeList().length;
    if (total <= 0) return 0;
    return (total / _groupSize).ceil();
  }

  bool _needsGrouping() {
    return _episodeList().length > _groupSize;
  }

  int _groupStart() {
    return _groupOf(widget.viewingSourceId) * _groupSize;
  }

  List<MovieUrlInfo> _visibleEpisodes() {
    final list = _episodeList();
    if (!_needsGrouping()) return list;
    final start = _groupStart();
    final end = (start + _groupSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  String _groupLabel(int index) {
    final total = _episodeList().length;
    final start = index * _groupSize + 1;
    final end = ((index + 1) * _groupSize).clamp(0, total);
    return '$start-$end';
  }

  bool _usesWideTiles() {
    final list = _visibleEpisodes();
    for (final e in list) {
      if (e.episode.length > _epNameWideLen) return true;
    }
    return false;
  }

  int _epCols(double screenWidth) {
    final bp = Breakpoint.ofWidth(screenWidth);
    final isWide = _usesWideTiles();
    if (bp == 'lg' || bp == 'xl') {
      return isWide ? 3 : 5;
    }
    if (bp == 'md') {
      return isWide ? 3 : 4;
    }
    return isWide ? 2 : 3;
  }

  void _syncSourceBar(bool smooth) {
    if (widget.sources.isEmpty || !_sourceScroller.hasClients) return;
    final index = widget.sources.indexWhere((s) => s.id == widget.viewingSourceId);
    if (index < 0) return;

    double targetOffset = 0;
    for (int i = 0; i < index; i++) {
      final s = widget.sources[i];
      final isAct = s.id == widget.viewingSourceId;
      final textW = s.name.length * 13.0;
      final itemW = textW + (isAct ? 40.0 : 24.0);
      targetOffset += itemW + 8.0;
    }

    final maxScroll = _sourceScroller.position.maxScrollExtent;
    final safeOffset = targetOffset.clamp(0.0, maxScroll);
    try {
      if (smooth) {
        _sourceScroller.animateTo(safeOffset,
            duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      } else {
        _sourceScroller.jumpTo(safeOffset);
      }
    } catch (_) {}
  }

  void _syncGroupBar(bool smooth) {
    if (!_needsGrouping() || !_groupScroller.hasClients) return;
    final g = _groupOf(widget.viewingSourceId);
    final targetOffset = (g * 76.0).clamp(0.0, _groupScroller.position.maxScrollExtent);
    try {
      if (smooth) {
        _groupScroller.animateTo(targetOffset,
            duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      } else {
        _groupScroller.jumpTo(targetOffset);
      }
    } catch (_) {}
  }

  void _checkReadyAndScroll(bool smooth) {
    _scrollToFocusedEpisode(smooth);
  }

  void _scrollToFocusedEpisode(bool smooth) {
    if (!_listScroller.hasClients) return;
    final list = _episodeList();
    if (list.isEmpty) return;

    final g = _groupOf(widget.viewingSourceId);
    final start = g * _groupSize;
    final end = start + _groupSize;
    final inGroup = widget.viewingSourceId == widget.playingSourceId &&
        widget.episodeIndex >= start &&
        widget.episodeIndex < end &&
        widget.episodeIndex < list.length;

    // 1. 同步横向滚动分组栏与播放源栏，使选中的胶囊进入视野首位
    _syncGroupBar(smooth);
    _syncSourceBar(smooth);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final cols = _epCols(screenWidth);

    // 2. 纵向列表定位：基于 headerHeight 与行高精确推移，绝不被吸顶栏遮挡
    try {
      if (inGroup) {
        final localIndex = widget.episodeIndex - start;
        final targetRow = localIndex ~/ cols;
        final visibleCount = _visibleEpisodes().length;
        final maxRow = max(0, ((visibleCount / cols).ceil() - 1));
        final safeRow = min(targetRow, maxRow);

        // 第一组首行或无分组前1-2行剧集：保持自然置顶（标题+吸顶栏+首行完整可见，绝不遮挡）
        if ((g == 0 && safeRow == 0) || (safeRow <= 1 && !_needsGrouping())) {
          if (smooth) {
            _listScroller.animateTo(0.0,
                duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
          } else {
            _listScroller.jumpTo(0.0);
          }
          return;
        }

        final targetOffset = (_headerHeight + safeRow * _epRowHeight)
            .clamp(0.0, _listScroller.position.maxScrollExtent);
        if (smooth) {
          _listScroller.animateTo(targetOffset,
              duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
        } else {
          _listScroller.jumpTo(targetOffset);
        }
      } else {
        // 目标分组不含当前剧集时，吸顶对齐到 ListItemGroup 顶部（header groupBar 吸顶，首行展示该组第1行）
        final targetOffset = _headerHeight.clamp(0.0, _listScroller.position.maxScrollExtent);
        if (smooth) {
          _listScroller.animateTo(targetOffset,
              duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        } else {
          _listScroller.jumpTo(targetOffset);
        }
      }
    } catch (_) {}
  }

  void _showEpisodeTitle(String name) {
    final text = name.trim();
    if (text.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgElevated,
        title: const Text('剧集名称', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
        content: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  bool _isEpisodeOn(int index) {
    return widget.viewingSourceId == widget.playingSourceId && widget.episodeIndex == index;
  }

  Widget _buildSourceChip(PlaySource source) {
    final active = widget.viewingSourceId == source.id;
    return InkWell(
      onTap: () {
        if (widget.onViewSource != null) {
          widget.onViewSource!(source.id);
        }
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent : AppTheme.bgChip,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              const Icon(Icons.check_rounded, size: 12, color: AppTheme.textPrimary),
              const SizedBox(width: 4),
            ],
            Text(
              source.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChip(int index) {
    final active = _groupOf(widget.viewingSourceId) == index;
    return InkWell(
      onTap: () {
        _setGroup(widget.viewingSourceId, index, true);
        _syncGroupBar(true);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _groupLabel(index),
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppTheme.border, height: 1),

        // 播放源横滑栏 (sourceRow)
        if (widget.sources.isNotEmpty)
          Container(
            height: 32,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.separated(
              controller: _sourceScroller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12, right: 16),
              itemCount: widget.sources.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _buildSourceChip(widget.sources[index]),
            ),
          ),

        // 选集分组横滑栏 (groupBar)
        if (_needsGrouping())
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Container(
              height: 40,
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: ListView.separated(
                controller: _groupScroller,
                scrollDirection: Axis.horizontal,
                itemCount: _groupCount(),
                separatorBuilder: (context, index) => const SizedBox(width: 4),
                itemBuilder: (context, index) => _buildGroupChip(index),
              ),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEpisodeTile(MovieUrlInfo ep, int index, bool isWide) {
    final active = _isEpisodeOn(index);
    return InkWell(
      onTap: () {
        if (active || widget.onSelectEpisode == null) {
          _showEpisodeTitle(ep.episode);
          return;
        }
        widget.onSelectEpisode!(widget.viewingSourceId, index);
      },
      onLongPress: () => _showEpisodeTitle(ep.episode),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        constraints: const BoxConstraints(minHeight: _epMinHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSm, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.accentSoft : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: active ? Border.all(color: AppTheme.accent, width: 2) : null,
        ),
        child: Text(
          ep.episode,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
          maxLines: isWide ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final visibleEps = _visibleEpisodes();
    final isWide = _usesWideTiles();
    final cols = _epCols(screenWidth);
    final groupStart = _groupStart();
    final rowCount = (visibleEps.length / cols).ceil();

    final groupBarHeight = 1.0 +
        (widget.sources.isNotEmpty ? 40.0 : 0.0) +
        (_needsGrouping() ? 48.0 : 0.0) +
        8.0;

    return CustomScrollView(
      controller: _listScroller,
      slivers: [
        // Film Detail Header
        SliverToBoxAdapter(
          child: Container(
            key: _headerKey,
            child: FilmDetailHeader(
              filmId: widget.filmId,
              picture: widget.picture,
              name: widget.name,
              subTitle: widget.subTitle,
              actor: widget.actor,
              plot: widget.plot,
              descriptor: widget.descriptor,
            ),
          ),
        ),

        // 吸顶播放源与分组控制栏 (对应 OHOS ListItemGroup header sticky)
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyGroupBarDelegate(
            height: groupBarHeight,
            child: _buildGroupBar(),
          ),
        ),

        // 选集列表（对齐 OHOS epRow: 固定 54dp 行高，44dp 净高）
        if (visibleEps.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('暂无数据', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, row) {
                return Container(
                  height: _epRowHeight,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                  child: Row(
                    children: [
                      for (int col = 0; col < cols; col++) ...[
                        if (col > 0) const SizedBox(width: AppTheme.spaceSm),
                        Expanded(
                          child: (row * cols + col < visibleEps.length)
                              ? _buildEpisodeTile(
                                  visibleEps[row * cols + col],
                                  groupStart + (row * cols + col),
                                  isWide,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              },
              childCount: rowCount,
            ),
          ),
      ],
    );
  }
}

class _StickyGroupBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyGroupBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.bg,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyGroupBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
