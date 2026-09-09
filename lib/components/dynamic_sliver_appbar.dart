import 'package:flutter/material.dart';

/// 筛选栏 Sliver。API 对齐 EcoTV `views/filter/dynamic_sliver_appbar.dart`。
///
/// 不给子组件写死高度：让 FilterBar 被行撑开，sliver 吃子组件固有高度。
/// [maxHeight] 仅作上限（EcoTV 传入屏幕高），不参与首帧估高。
class DynamicSliverAppBar extends StatefulWidget {
  final Widget? child;
  final double maxHeight;
  final ValueChanged<double>? onHeightListener;

  const DynamicSliverAppBar({
    super.key,
    required this.maxHeight,
    this.child,
    this.onHeightListener,
  });

  @override
  State<DynamicSliverAppBar> createState() => _DynamicSliverAppBarState();
}

class _DynamicSliverAppBarState extends State<DynamicSliverAppBar> {
  final GlobalKey _childKey = GlobalKey();
  double? _height;

  void _syncHeight() {
    final box = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    var h = box.size.height;
    if (h <= 0) return;
    if (widget.maxHeight > 0 && h > widget.maxHeight) h = widget.maxHeight;
    if (_height != null && (h - _height!).abs() < 0.5) return;
    _height = h;
    widget.onHeightListener?.call(h);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHeight());
    return SliverToBoxAdapter(
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _syncHeight());
          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: KeyedSubtree(
            key: _childKey,
            child: widget.child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
