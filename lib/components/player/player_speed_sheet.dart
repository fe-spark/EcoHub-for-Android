import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import 'player_speed.dart';

/// 播放倍速选择轻量悬浮底卡（对齐 OHOS 影院级微光卡片 PlayerSpeedDialog）
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (context) => PlayerSpeedSheet(
        currentSpeed: currentSpeed,
        onSelectSpeed: onSelectSpeed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(16, 0, 16, math.max(16.0, bottomInset + 8.0)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xF0181A22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x29FFFFFF), width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x73000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 顶部标题栏：图标 + 标题 + 当前倍速徽章 + 关闭按钮
              Row(
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    size: 18,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '播放倍速',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      '当前 ${PlayerSpeed.label(currentSpeed)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0x1AFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // 2. 水平单行流线胶囊轨道 (Horizontal Capsule Row)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: speeds.map((speed) {
                    final active = (currentSpeed - speed).abs() < 0.01;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          onSelectSpeed(speed);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.accent
                                : const Color(0x12FFFFFF),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            border: Border.all(
                              color: active ? AppTheme.accent : const Color(0x1AFFFFFF),
                              width: active ? 1.0 : 0.5,
                            ),
                          ),
                          child: Text(
                            PlayerSpeed.label(speed),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: active ? FontWeight.bold : FontWeight.w500,
                              color: active ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
