import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../models/film_models.dart';
import 'film_detail_header.dart';

const int _groupSize = 100;
const int _epNameWideLen = 6;

/// 播放页选集与详情面板
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

  void _setGroup(String sourceId, int groupIndex) {
    if (sourceId.isEmpty) return;
    final count = _groupCount();
    final safe = count <= 0 ? 0 : groupIndex.clamp(0, count - 1);
    setState(() {
      _groupIndexes[sourceId] = safe;
    });
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

  @override
  Widget build(BuildContext context) {
    final visibleEps = _visibleEpisodes();
    final isWide = _usesWideTiles();
    final cols = isWide ? 2 : 3;
    final groupStart = _groupStart();
    final count = _groupCount();

    return CustomScrollView(
      slivers: [
        // Film Detail Header
        SliverToBoxAdapter(
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

        // Sources & Group Chips
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppTheme.border, height: 1),

              // Source chips row
              if (widget.sources.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
                  child: Row(
                    children: widget.sources.map((source) {
                      final active = widget.viewingSourceId == source.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (active) ...[
                                  const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  source.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                    color: active ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Group tabs row (if > 100 episodes)
              if (_needsGrouping())
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(count, (index) {
                        final active = _groupOf(widget.viewingSourceId) == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: InkWell(
                            onTap: () => _setGroup(widget.viewingSourceId, index),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: active ? AppTheme.accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _groupLabel(index),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                  color: active ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

              const SizedBox(height: 6),
            ],
          ),
        ),

        // Episodes Grid
        if (visibleEps.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('暂无选集数据', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: isWide ? 2.8 : 2.2,
                crossAxisSpacing: AppTheme.spaceSm,
                mainAxisSpacing: AppTheme.spaceSm,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ep = visibleEps[index];
                  final epIndex = groupStart + index;
                  final active = _isEpisodeOn(epIndex);

                  return InkWell(
                    onTap: () {
                      if (active || widget.onSelectEpisode == null) {
                        _showEpisodeTitle(ep.episode);
                        return;
                      }
                      widget.onSelectEpisode!(widget.viewingSourceId, epIndex);
                    },
                    onLongPress: () => _showEpisodeTitle(ep.episode),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.accentSoft : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: active ? AppTheme.accent : Colors.transparent,
                          width: active ? 1.5 : 0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ep.episode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.bold : FontWeight.w500,
                          color: active ? AppTheme.accent : AppTheme.textSecondary,
                        ),
                        maxLines: isWide ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
                childCount: visibleEps.length,
              ),
            ),
          ),
      ],
    );
  }
}
