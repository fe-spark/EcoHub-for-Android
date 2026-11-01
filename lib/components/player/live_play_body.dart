import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../components/player/play_side_tabs.dart';
import '../../models/film_models.dart';
import '../../utils/breakpoint.dart';

/// 现场播放页的主体布局（分屏与非分屏），对齐 PlayPage
class LivePlayBody extends StatelessWidget {
  final bool isSplit;
  final bool isFull;
  final Widget playerWidget;
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
  final ValueChanged<String> onViewSource;
  final void Function(String sourceId, int index) onSelectEpisode;
  final bool relateLoading;
  final List<MovieBasicInfo> related;
  final void Function(MovieBasicInfo film) onOpenRelated;
  final String sourceName;

  const LivePlayBody({
    super.key,
    this.isSplit = false,
    this.isFull = false,
    required this.playerWidget,
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
    required this.onViewSource,
    required this.onSelectEpisode,
    required this.relateLoading,
    required this.related,
    required this.onOpenRelated,
    required this.sourceName,
  });

  /// 横屏/平板专属侧边栏宽度计算，对齐 OHOS: min(360, max(280, windowWidth * 0.38))
  static double sidebarWidthOf(double screenWidth) {
    if (screenWidth <= 0) return 280.0;
    return (screenWidth * 0.38).clamp(280.0, 360.0);
  }

  Widget _buildSideTabs(BuildContext context, {required int columns, bool split = false, double rightInset = 0}) {
    return PlaySideTabs(
      activeTab: activeTab,
      onTabChange: onTabChange,
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
      isSplit: split,
      rightInset: rightInset,
      onViewSource: onViewSource,
      onSelectEpisode: onSelectEpisode,
      relateLoading: relateLoading,
      related: related,
      columns: columns,
      onOpenRelated: onOpenRelated,
      sourceName: sourceName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.size.width > media.size.height && media.size.height > 0;
    final viewPadding = media.viewPadding;
    final topInset = viewPadding.top;
    final bottomInset = viewPadding.bottom;
    final leftInset = viewPadding.left;
    final rightInset = viewPadding.right;
    final showSplit = (isSplit || isLandscape) && !isFull;

    return Row(
      children: [
        // 1. 左侧主区域 (所有模式下单例常驻播放器；竖屏或平板横屏时下方自适应内容)
        Expanded(
          child: Container(
            height: double.infinity,
            color: isFull ? Colors.black : AppTheme.bg,
            padding: EdgeInsets.only(
              top: (isFull || isLandscape) ? 0.0 : topInset,
            ),
            child: Column(
              children: [
                (isFull || isLandscape)
                    ? Expanded(child: SizedBox.expand(child: playerWidget))
                    : AspectRatio(aspectRatio: 16 / 9, child: playerWidget),
                if (!isLandscape && !isFull) ...[
                  Container(height: 8, color: AppTheme.bgElevated),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: leftInset,
                        right: rightInset,
                        bottom: bottomInset,
                      ),
                      child: _buildSideTabs(
                        context,
                        columns: Breakpoint.gridColsOf(media.size.width),
                        split: false,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 2. 右侧全高侧边栏 (仅在横屏且未全屏时出现，对齐 OHOS)
        if (showSplit)
          Container(
            width: sidebarWidthOf(media.size.width),
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.bgElevated,
              border: Border(
                left: BorderSide(width: 0.5, color: Color(0x1AFFFFFF)),
              ),
            ),
            padding: EdgeInsets.only(
              top: topInset,
              bottom: bottomInset,
            ),
            child: _buildSideTabs(
              context,
              columns: 2,
              split: true,
              rightInset: rightInset,
            ),
          ),
      ],
    );
  }
}
