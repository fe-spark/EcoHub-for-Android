import 'package:flutter/material.dart';
import '../common/app_theme.dart';

/// 统一图标组件
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const AppIcon({
    super.key,
    required this.icon,
    this.size = 20,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
