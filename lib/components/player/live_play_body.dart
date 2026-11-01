import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../components/player/play_side_tabs.dart';
import '../../models/film_models.dart';
import '../../utils/breakpoint.dart';
import '../../utils/split_cutout_insets.dart';

/// 现场播放页的主体布局（分屏与非分屏），对齐 PlayPage
class LivePlayBody extends StatelessWidget {
  final bool isSplit;
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
    required this.isSplit,
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

  /// 横屏/平板专属侧边栏宽度计算，对齐 OHOS: min(380, max(260, windowWidth * 0.35))
  static double sidebarWidthOf(double screenWidth) {
    if (screenWidth <= 0) return 280.0;
    final target = screenWidth * 0.35;
    final minW = screenWidth < 700 ? 240.0 : 280.0;
    return target.clamp(minW, 380.0);
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
    if (isSplit) {
      final media = MediaQuery.of(context);
      final cutout = SplitCutoutInsets.resolve(
        media.viewPadding,
        padding: media.padding,
        displayFeatures: media.displayFeatures,
        size: media.size,
      );
      final sidebarWidth = sidebarWidthOf(media.size.width);

      return Row(
        children: [
          // 1. 左侧主体播放器：撑满高度与剩余宽度，100% 满高影院画幅，彻底消灭上下挤压黑边
          Expanded(
            child: SizedBox.expand(
              child: playerWidget,
            ),
          ),
          Container(width: 0.5, color: const Color(0x24FFFFFF)),
          // 2. 右侧专属全高侧边栏：自适应 260~380dp，与竖屏 100% 一致的 sideTabs 选集推荐
          SizedBox(
            width: sidebarWidth,
            height: double.infinity,
            child: Container(
              color: AppTheme.bgElevated,
              child: SafeArea(
                top: true,
                bottom: true,
                left: false,
                right: false,
                child: _buildSideTabs(
                  context,
                  columns: sidebarWidth > 320 ? 3 : 2,
                  split: true,
                  rightInset: cutout.right,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: playerWidget,
        ),
        Container(height: 8, color: AppTheme.bgElevated),
        Expanded(
          child: _buildSideTabs(
            context,
            columns: Breakpoint.gridColsOf(MediaQuery.sizeOf(context).width),
            split: false,
          ),
        ),
      ],
    );
  }
}
