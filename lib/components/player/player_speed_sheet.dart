import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import 'player_speed.dart';

/// 播放倍速选择底栏弹窗
class PlayerSpeedSheet extends StatelessWidget {
  static const List<double> speeds = PlayerSpeed.rates;
  final double currentSpeed;
  final ValueChanged<double> onSelectSpeed;

  const PlayerSpeedSheet({
    super.key,
    required this.currentSpeed,
    required this.onSelectSpeed,
  });

  static void show(BuildContext context, double currentSpeed, ValueChanged<double> onSelectSpeed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) => PlayerSpeedSheet(
        currentSpeed: currentSpeed,
        onSelectSpeed: onSelectSpeed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '播放倍速',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Divider(color: AppTheme.border),
            ...speeds.map((speed) {
              final active = (currentSpeed - speed).abs() < 0.01;
              return ListTile(
                title: Center(
                  child: Text(
                    PlayerSpeed.label(speed),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? AppTheme.accent : AppTheme.textSecondary,
                    ),
                  ),
                ),
                onTap: () {
                  onSelectSpeed(speed);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
