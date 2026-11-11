import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import 'player_scale.dart';
import 'player_speed.dart';

/// 播放设置底卡：倍速、画面填充、静音。选完不关闭，便于一次改多项。
class PlayerSettingsSheet extends StatefulWidget {
  final double currentSpeed;
  final PlayerScaleMode scaleMode;
  final bool muted;
  final ValueChanged<double> onSelectSpeed;
  final ValueChanged<PlayerScaleMode> onSelectScale;
  final VoidCallback onToggleMute;

  const PlayerSettingsSheet({
    super.key,
    required this.currentSpeed,
    required this.scaleMode,
    required this.muted,
    required this.onSelectSpeed,
    required this.onSelectScale,
    required this.onToggleMute,
  });

  static void show(
    BuildContext context, {
    required double currentSpeed,
    required PlayerScaleMode scaleMode,
    required bool muted,
    required ValueChanged<double> onSelectSpeed,
    required ValueChanged<PlayerScaleMode> onSelectScale,
    required VoidCallback onToggleMute,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (context) => PlayerSettingsSheet(
        currentSpeed: currentSpeed,
        scaleMode: scaleMode,
        muted: muted,
        onSelectSpeed: onSelectSpeed,
        onSelectScale: onSelectScale,
        onToggleMute: onToggleMute,
      ),
    );
  }

  @override
  State<PlayerSettingsSheet> createState() => _PlayerSettingsSheetState();
}

class _PlayerSettingsSheetState extends State<PlayerSettingsSheet> {
  late double _speed;
  late PlayerScaleMode _scale;
  late bool _muted;

  @override
  void initState() {
    super.initState();
    _speed = widget.currentSpeed;
    _scale = widget.scaleMode;
    _muted = widget.muted;
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
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
              Row(
                children: [
                  const Icon(Icons.settings_rounded, size: 18, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  const Text(
                    '播放设置',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(color: Color(0x1AFFFFFF), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('播放速度', style: TextStyle(fontSize: 12, color: Color(0x8CFFFFFF))),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: PlayerSpeed.rates.map((speed) {
                    final active = (_speed - speed).abs() < 0.01;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _speed = speed);
                          widget.onSelectSpeed(speed);
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? AppTheme.accent : const Color(0x12FFFFFF),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            border: Border.all(
                              color: active ? AppTheme.accent : const Color(0x1AFFFFFF),
                              width: active ? 1.0 : 0.5,
                            ),
                          ),
                          child: Text(
                            speed == 1.0 ? '1.0x 标准' : PlayerSpeed.label(speed),
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
              const SizedBox(height: 16),
              const Text('画面填充', style: TextStyle(fontSize: 12, color: Color(0x8CFFFFFF))),
              const SizedBox(height: 8),
              Row(
                children: PlayerScale.modes.map((mode) {
                  final active = _scale == mode;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: mode == PlayerScale.modes.last ? 0 : 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _scale = mode);
                          widget.onSelectScale(mode);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? AppTheme.accent : const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active ? AppTheme.accent : const Color(0x1FFFFFFF),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                PlayerScale.label(mode),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: active ? Colors.white : const Color(0xD9FFFFFF),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                PlayerScale.desc(mode),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: active ? const Color(0xD9FFFFFF) : const Color(0x73FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Material(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    setState(() => _muted = !_muted);
                    widget.onToggleMute();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 44,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _muted ? '已静音' : '声音',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _muted ? const Color(0x1AFFFFFF) : AppTheme.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _muted ? '关闭' : '开启',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _muted ? const Color(0xA6FFFFFF) : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
