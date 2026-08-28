import 'package:flutter/material.dart';
import '../common/app_theme.dart';

/// 回到顶部浮动按钮
class ScrollFab extends StatelessWidget {
  final bool visible;
  final VoidCallback onClickFab;

  const ScrollFab({
    super.key,
    required this.visible,
    required this.onClickFab,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: visible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: FloatingActionButton.small(
            onPressed: visible ? onClickFab : null,
            backgroundColor: AppTheme.bgCard,
            foregroundColor: AppTheme.textPrimary,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: const Icon(Icons.keyboard_arrow_up_rounded, size: 22),
          ),
        ),
      ),
    );
  }
}
