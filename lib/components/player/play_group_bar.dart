import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../models/film_models.dart';

/// 播放源切换与大选集分组横滑栏组件
class PlayGroupBar extends StatelessWidget {
  static const double dividerHeight = 1.0;
  static const double sourceRowHeight = 32.0;
  static const double sourceRowMarginTop = 10.0;
  static const double sourceBottomSpacing = 10.0;
  static const double groupRowHeight = 30.0;
  static const double groupRowMarginTop = 10.0;
  static const double groupBottomSpacing = 12.0;

  static double calculateHeight({
    required bool hasSources,
    required bool needsGrouping,
  }) {
    if (!hasSources && !needsGrouping) return 0.0;
    double h = dividerHeight;
    if (hasSources) {
      h += sourceRowMarginTop + sourceRowHeight;
    }
    if (needsGrouping) {
      h += groupRowMarginTop + groupRowHeight + groupBottomSpacing;
    } else if (hasSources) {
      h += sourceBottomSpacing;
    }
    return h;
  }

  final List<PlaySource> sources;
  final String viewingSourceId;
  final ValueChanged<String>? onViewSource;
  final bool needsGrouping;
  final int groupCount;
  final int currentGroup;
  final ValueChanged<int> onSelectGroup;
  final String Function(int index) groupLabel;
  final ScrollController? sourceScroller;
  final ScrollController? groupScroller;
  final double rightInset;
  final Map<String, GlobalKey>? sourceKeys;
  final Map<int, GlobalKey>? groupKeys;
  final GlobalKey? sourceRowKey;
  final GlobalKey? groupRowKey;

  const PlayGroupBar({
    super.key,
    required this.sources,
    required this.viewingSourceId,
    this.onViewSource,
    required this.needsGrouping,
    required this.groupCount,
    required this.currentGroup,
    required this.onSelectGroup,
    required this.groupLabel,
    this.sourceScroller,
    this.groupScroller,
    this.rightInset = 0,
    this.sourceKeys,
    this.groupKeys,
    this.sourceRowKey,
    this.groupRowKey,
  });

  Widget _buildSourceChip(PlaySource source) {
    final active = viewingSourceId == source.id;
    return InkWell(
      key: sourceKeys?[source.id],
      onTap: () => onViewSource?.call(source.id),
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        height: sourceRowHeight,
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
    final active = currentGroup == index;
    return InkWell(
      key: groupKeys?[index],
      onTap: () => onSelectGroup(index),
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: groupRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.accent : AppTheme.bgChip,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          groupLabel(index),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSources = sources.length > 1;
    if (!hasSources && !needsGrouping) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppTheme.borderSolid, height: dividerHeight),

        // 播放源横滑栏 (sourceRow)
        if (hasSources)
          Container(
            height: sourceRowHeight,
            margin: const EdgeInsets.only(top: sourceRowMarginTop),
            child: SingleChildScrollView(
              controller: sourceScroller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 12, right: 16 + rightInset),
              child: Row(
                key: sourceRowKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < sources.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _buildSourceChip(sources[i]),
                  ],
                ],
              ),
            ),
          ),

        // 选集分组横滑栏 (groupBar)
        if (needsGrouping) ...[
          Container(
            height: groupRowHeight,
            margin: const EdgeInsets.only(top: groupRowMarginTop),
            child: SingleChildScrollView(
              controller: groupScroller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 12, right: 16 + rightInset),
              child: Row(
                key: groupRowKey,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < groupCount; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _buildGroupChip(i),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: groupBottomSpacing),
        ] else ...[
          const SizedBox(height: sourceBottomSpacing),
        ],
      ],
    );
  }
}

/// 选集控制栏吸顶 Delegate
class StickyGroupBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  StickyGroupBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      width: double.infinity,
      color: AppTheme.bg,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant StickyGroupBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
