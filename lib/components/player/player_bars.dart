import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../utils/format_util.dart';

/// 播放器返回按钮，对齐 OHOS `PlayerBackBtn`
class PlayerBackBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final double iconSize;
  final double boxSize;

  const PlayerBackBtn({
    super.key,
    this.onTap,
    this.iconSize = 18,
    this.boxSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: boxSize,
        height: boxSize,
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 播放器操作胶囊标签（倍速、画面比例、弹幕开关），对齐 OHOS `PlayerChip`
class PlayerChip extends StatelessWidget {
  final String label;
  final bool highlight;
  final bool canTap;
  final VoidCallback? onTap;

  const PlayerChip({
    super.key,
    required this.label,
    this.highlight = false,
    this.canTap = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canTap ? onTap : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlight ? const Color(0x38FA8C16) : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: highlight ? const Color(0x99FA8C16) : Colors.white.withValues(alpha: 0.20),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: highlight ? AppTheme.accent : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
/// 播放器顶部控制栏（全屏模式），对齐 OHOS `PlayerSkin.topBar`
class PlayerTopBar extends StatelessWidget {
  final bool isFull;
  final bool showHud;
  final String errorText;
  final String title;
  final double topInset;
  final double leftInset;
  final double rightInset;
  final bool hasPrev;
  final bool hasNext;
  final String castDeviceName;
  final bool canCast;
  final VoidCallback onBack;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onCast;
  final VoidCallback? onStopCast;
  final VoidCallback? onPip;

  const PlayerTopBar({
    super.key,
    required this.isFull,
    required this.showHud,
    required this.errorText,
    required this.title,
    this.topInset = 0,
    this.leftInset = 0,
    this.rightInset = 0,
    this.hasPrev = false,
    this.hasNext = false,
    this.castDeviceName = '',
    this.canCast = false,
    required this.onBack,
    this.onPrev,
    this.onNext,
    this.onCast,
    this.onStopCast,
    this.onPip,
  });


  @override
  Widget build(BuildContext context) {
    if (!isFull || (!showHud && errorText.isEmpty)) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: math.max(8.0, topInset + 4.0),
        left: math.max(8.0, leftInset + 4.0),
        right: math.max(8.0, rightInset + 4.0),
        bottom: 8,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xAD000000), Color(0x57000000), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          PlayerBackBtn(onTap: onBack),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (hasPrev || hasNext) ...[
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: hasPrev ? Colors.white : Colors.white38,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 36),
              ),
              icon: const Icon(Icons.skip_previous_rounded, size: 16),
              label: const Text('上集', style: TextStyle(fontSize: 13)),
              onPressed: hasPrev ? onPrev : null,
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: hasNext ? Colors.white : Colors.white38,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 36),
              ),
              icon: const Icon(Icons.skip_next_rounded, size: 16),
              label: const Text('下集', style: TextStyle(fontSize: 13)),
              onPressed: hasNext ? onNext : null,
            ),
          ],
          if (castDeviceName.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: AppTheme.danger, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: onStopCast,
            )
          else if (canCast && onCast != null)
            IconButton(
              icon: const Icon(Icons.cast_rounded, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: onCast,
            ),
          if (onPip != null && castDeviceName.isEmpty && errorText.isEmpty)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 20),
              tooltip: '画中画',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: onPip,
            ),
        ],
      ),
    );
  }
}

/// 播放器底部控制栏，对齐 OHOS `PlayerSkin.bottomBar`
class PlayerBottomBar extends StatefulWidget {
  final bool isReady;
  final bool isOpening;
  final bool showHud;
  final String errorText;
  final bool cinemaHud;
  final bool isFull;
  final bool isPlaying;
  final bool muted;
  final Duration currentPosition;
  final Duration totalDuration;
  final double currentSpeed;
  final String scaleLabel;
  final double leftInset;
  final double rightInset;
  final double bottomInset;
  final bool hasNext;
  final VoidCallback? onNext;
  final bool danmakuEnabled;
  final bool canDanmaku;
  final VoidCallback? onToggleDanmaku;
  final String castDeviceName;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleFull;
  final VoidCallback onToggleMute;
  final VoidCallback onSpeed;
  final VoidCallback? onScale;
  final ValueChanged<Duration>? onSeekStart;
  final ValueChanged<Duration>? onSeekProgress;
  final ValueChanged<Duration>? onSeekEnd;
  final ValueChanged<Duration> onSeekTo;

  const PlayerBottomBar({
    super.key,
    required this.isReady,
    required this.isOpening,
    required this.showHud,
    required this.errorText,
    required this.cinemaHud,
    required this.isFull,
    required this.isPlaying,
    required this.muted,
    required this.currentPosition,
    required this.totalDuration,
    required this.currentSpeed,
    required this.scaleLabel,
    this.leftInset = 0,
    this.rightInset = 0,
    this.bottomInset = 0,
    this.hasNext = false,
    this.onNext,
    this.danmakuEnabled = true,
    this.canDanmaku = false,
    this.onToggleDanmaku,
    this.castDeviceName = '',
    required this.onTogglePlay,
    required this.onToggleFull,
    required this.onToggleMute,
    required this.onSpeed,
    this.onScale,
    this.onSeekStart,
    this.onSeekProgress,
    this.onSeekEnd,
    required this.onSeekTo,
  });

  @override
  State<PlayerBottomBar> createState() => _PlayerBottomBarState();
}

class _PlayerBottomBarState extends State<PlayerBottomBar> {
  bool _isDragging = false;
  double _dragMs = 0;


  Widget _buildSlider(BuildContext context) {
    final maxMs = widget.totalDuration.inMilliseconds > 0 ? widget.totalDuration.inMilliseconds.toDouble() : 1.0;
    final curMs = _isDragging
        ? _dragMs.clamp(0.0, maxMs)
        : widget.currentPosition.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: AppTheme.accent,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
      ),
      child: Slider(
        value: curMs,
        min: 0.0,
        max: maxMs,
        onChangeStart: (val) {
          setState(() {
            _isDragging = true;
            _dragMs = val;
          });
          widget.onSeekStart?.call(Duration(milliseconds: val.toInt()));
        },
        onChanged: (val) {
          setState(() {
            _dragMs = val;
          });
          widget.onSeekProgress?.call(Duration(milliseconds: val.toInt()));
        },
        onChangeEnd: (val) {
          setState(() {
            _isDragging = false;
          });
          final target = Duration(milliseconds: val.toInt());
          widget.onSeekEnd?.call(target);
          widget.onSeekTo(target);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isReady || widget.isOpening || !widget.showHud || widget.errorText.isNotEmpty || widget.castDeviceName.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final displaySec = _isDragging ? (_dragMs / 1000.0) : widget.currentPosition.inSeconds.toDouble();
    final timeStr =
        '${FormatUtil.duration(displaySec)} / ${FormatUtil.duration(widget.totalDuration.inSeconds.toDouble())}';
    final isPortrait = !widget.isFull && !widget.cinemaHud;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: widget.isFull
            ? math.max(14.0, widget.leftInset + 10.0)
            : math.max(12.0, widget.leftInset + 6.0),
        right: widget.isFull
            ? math.max(14.0, widget.rightInset + 10.0)
            : 12.0,
        bottom: widget.isFull
            ? math.max(12.0, widget.bottomInset)
            : (widget.cinemaHud ? math.max(20.0, widget.bottomInset + 4.0) : math.max(8.0, widget.bottomInset)),
        top: isPortrait ? 2.0 : 8.0,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x5C000000), Color(0xC7000000)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final isCompact = availableWidth < 460;
          final isVeryCompact = availableWidth < 380;
          final showNext = widget.hasNext && widget.onNext != null && !isVeryCompact;
          final showScale = widget.onScale != null && !isCompact && !isPortrait;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 顶层通栏进度条（100% 满宽自由拖拽，彻底解决挤压与误触）
              _buildSlider(context),
              const SizedBox(height: 2),

              // 2. 底部控制栏（左侧播控与时间，中间弹性留白，右侧功能群组）
              Row(
                children: [
                  // 左侧控制群组：播放/暂停、下一集、时间刻度
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onTogglePlay,
                      ),
                      if (showNext)
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 18),
                          tooltip: '下一集',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onNext,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 右侧功能调节群组：倍速胶囊、比例胶囊、弹幕开关、静音开关、全屏切换
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerChip(
                        label: '${widget.currentSpeed}x',
                        highlight: widget.currentSpeed != 1.0,
                        onTap: widget.onSpeed,
                      ),
                      if (showScale) ...[
                        const SizedBox(width: 8),
                        PlayerChip(
                          label: widget.scaleLabel,
                          highlight: widget.scaleLabel != '适应',
                          onTap: widget.onScale,
                        ),
                      ],
                      if (widget.canDanmaku) ...[
                        const SizedBox(width: 8),
                        PlayerChip(
                          label: '弹幕',
                          highlight: widget.danmakuEnabled,
                          onTap: widget.onToggleDanmaku,
                        ),
                      ],
                      const SizedBox(width: 2),
                      IconButton(
                        icon: Icon(
                          widget.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onToggleMute,
                      ),
                      if (widget.castDeviceName.isEmpty)
                        IconButton(
                          icon: Icon(
                            widget.isFull ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onToggleFull,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
