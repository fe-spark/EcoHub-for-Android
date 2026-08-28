import 'package:flutter/material.dart';
import '../common/app_theme.dart';

/// 统一加载中提示组件
class LoadingView extends StatelessWidget {
  final String label;

  const LoadingView({
    super.key,
    this.label = '加载中',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.accent,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
