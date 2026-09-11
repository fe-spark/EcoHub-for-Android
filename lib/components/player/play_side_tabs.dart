import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../models/film_models.dart';
import '../empty_state.dart';
import '../film_grid.dart';
import '../loading_view.dart';
import 'play_detail_panel.dart';

/// 播放页面侧边/底部切换面板（详情与相关推荐）
class PlaySideTabs extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChange;
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
  final bool isSplit;
  final double rightInset;
  final ValueChanged<String> onViewSource;
  final void Function(String sourceId, int index) onSelectEpisode;
  final bool relateLoading;
  final List<MovieBasicInfo> related;
  final int columns;
  final ValueChanged<MovieBasicInfo> onOpenRelated;

  const PlaySideTabs({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    required this.filmId,
    required this.picture,
    required this.name,
    required this.subTitle,
    required this.actor,
    required this.plot,
    this.descriptor,
    required this.sources,
    required this.playingSourceId,
    required this.viewingSourceId,
    required this.episodeIndex,
    this.isSplit = false,
    this.rightInset = 0,
    required this.onViewSource,
    required this.onSelectEpisode,
    required this.relateLoading,
    required this.related,
    required this.columns,
    required this.onOpenRelated,
  });

  Widget _buildTabItem(String title, int index) {
    final active = activeTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabChange(index),
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: active ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
            Container(
              width: 18,
              height: 3,
              margin: const EdgeInsets.only(top: 6),
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
    if (relateLoading) {
      return const LoadingView(label: '加载相关推荐');
    }
    if (related.isEmpty) {
      return const EmptyState(
        title: '暂无相关推荐',
        subtitle: '换一部片子再看看',
        icon: Icons.movie_outlined,
      );
    }
    return FilmGrid(
      films: related,
      columns: columns,
      padding: EdgeInsets.fromLTRB(12, 4, 12 + rightInset, 12),
      onClickFilm: onOpenRelated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Switcher
        Container(
          height: 44,
          padding: EdgeInsets.only(left: 12, right: 12 + rightInset),
          child: Row(
            children: [
              _buildTabItem('详情', 0),
              _buildTabItem('相关推荐', 1),
            ],
          ),
        ),
        // Tab Contents
        Expanded(
          child: activeTab == 0
              ? PlayDetailPanel(
                  filmId: filmId,
                  picture: picture,
                  name: name,
                  subTitle: subTitle,
                  actor: actor,
                  plot: plot,
                  descriptor: descriptor,
                  sources: sources,
                  playingSourceId: playingSourceId,
                  viewingSourceId: viewingSourceId,
                  episodeIndex: episodeIndex,
                  isSplit: isSplit,
                  episodeColumns: isSplit ? 3 : null,
                  rightInset: rightInset,
                  onViewSource: onViewSource,
                  onSelectEpisode: onSelectEpisode,
                )
              : _buildRelatedTab(),
        ),
      ],
    );
  }
}
