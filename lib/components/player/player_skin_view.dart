import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../utils/format_util.dart';
import 'player_gesture_handler.dart';
import 'player_error_pad.dart';

/// 播放器覆盖层控制栏组件（全量对齐鸿蒙端 PlayerSkin）
class PlayerSkinView extends StatelessWidget {
  final bool isFull;
  final bool showHud;
  final bool showBack;
  final String title;
  final bool isPlaying;
  final bool isBuffering;
  final bool isOpening;
  final bool isReady;
  final bool isCompleted;
  final bool muted;
  final String errorText;
  final Duration currentPosition;
  final Duration totalDuration;
  final double currentSpeed;
  final String scaleLabel;
  final bool hasPrev;
  final bool hasNext;
  final PlayerPanState panState;
  final VoidCallback onBack;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleFull;
  final VoidCallback onToggleMute;
  final VoidCallback onSpeed;
  final VoidCallback? onScale;
  final VoidCallback onRetry;
  final VoidCallback? onCopyError;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onSeekBack10;
  final VoidCallback onSeekFwd10;
  final ValueChanged<Duration> onSeekTo;

  const PlayerSkinView({
    super.key,
    required this.isFull,
    required this.showHud,
    this.showBack = true,
    required this.title,
    required this.isPlaying,
    required this.isBuffering,
    this.isOpening = false,
    this.isReady = false,
    this.isCompleted = false,
    this.muted = false,
    this.errorText = '',
    required this.currentPosition,
    required this.totalDuration,
    this.currentSpeed = 1.0,
    this.scaleLabel = '适应',
    this.hasPrev = false,
    this.hasNext = false,
    this.panState = const PlayerPanState(),
    required this.onBack,
    required this.onTogglePlay,
    required this.onToggleFull,
    required this.onToggleMute,
    required this.onSpeed,
    this.onScale,
    required this.onRetry,
    this.onCopyError,
    this.onPrev,
    this.onNext,
    required this.onSeekBack10,
    required this.onSeekFwd10,
    required this.onSeekTo,
  });

  bool get _isLoading => (isBuffering || isOpening) && errorText.isEmpty;

  bool get _showCenterPlay =>
      showHud && !_isLoading && errorText.isEmpty && (!isPlaying || isCompleted);

  double get _progressPercent {
    if (totalDuration.inMilliseconds <= 0) return 0.0;
    return (currentPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  Widget _buildSlider(BuildContext context) {
    final maxMs = totalDuration.inMilliseconds > 0 ? totalDuration.inMilliseconds.toDouble() : 1.0;
    final curMs = currentPosition.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

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
        onChanged: (val) {
          onSeekTo(Duration(milliseconds: val.toInt()));
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    if (!isFull || !showHud || errorText.isNotEmpty) return const SizedBox.shrink();

    return Container(
      height: 48 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 8, right: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xAA000000), Color(0x55000000), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasPrev)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.skip_previous_rounded, size: 16),
              label: const Text('上集', style: TextStyle(fontSize: 13)),
              onPressed: onPrev,
            ),
          if (hasNext)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.skip_next_rounded, size: 16),
              label: const Text('下集', style: TextStyle(fontSize: 13)),
              onPressed: onNext,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    if (!isReady || isOpening || !showHud || errorText.isNotEmpty) return const SizedBox.shrink();

    final timeStr =
        '${FormatUtil.duration(currentPosition.inSeconds.toDouble())} / ${FormatUtil.duration(totalDuration.inSeconds.toDouble())}';

    if (isFull) {
      return Container(
        padding: EdgeInsets.only(left: 12, right: 12, bottom: MediaQuery.of(context).padding.bottom + 4, top: 4),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSlider(context),
            Row(
              children: [
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  onPressed: onTogglePlay,
                ),
                Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                InkWell(
                  onTap: onSpeed,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text('${currentSpeed}x', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (onScale != null)
                  InkWell(
                    onTap: onScale,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(scaleLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                IconButton(
                  icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 20),
                  onPressed: onToggleMute,
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 22),
                  onPressed: onToggleFull,
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 竖屏底栏
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xB8000000), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: onTogglePlay,
          ),
          Expanded(child: _buildSlider(context)),
          Text(
            timeStr,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onSpeed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                '${currentSpeed}x',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (onScale != null)
            InkWell(
              onTap: onScale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  scaleLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          IconButton(
            icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 18),
            onPressed: onToggleMute,
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
            onPressed: onToggleFull,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterGroup(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 手势提示 (快进/音量/亮度/长按倍速)
          if (panState.kind != PlayerTipKind.none)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xBD000000),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(color: Color(0x38000000), blurRadius: 14, offset: Offset(0, 8))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (panState.kind == PlayerTipKind.seekFwd)
                    const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 18)
                  else if (panState.kind == PlayerTipKind.seekBack)
                    const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 18)
                  else if (panState.kind == PlayerTipKind.brightness)
                    const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 18)
                  else if (panState.kind == PlayerTipKind.volume)
                    Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 18)
                  else if (panState.kind == PlayerTipKind.speed)
                    const Icon(Icons.speed_rounded, color: AppTheme.accent, size: 18)
                  else if (panState.kind == PlayerTipKind.scale)
                    const Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    panState.text,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // 加载缓冲卡片
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xC7000000),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOpening ? '正在打开...' : '加载中...',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),

          // 中心播放/重播控制器
          if (_showCenterPlay)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFull) ...[
                  _buildCircleBtn(label: '-10', onTap: onSeekBack10),
                  const SizedBox(width: 28),
                ],
                GestureDetector(
                  onTap: onTogglePlay,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0x66000000),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: Icon(
                      isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                if (isFull) ...[
                  const SizedBox(width: 28),
                  _buildCircleBtn(label: '+10', onTap: onSeekFwd10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 顶部栏
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(context),
        ),

        // 中心交互组（提示、加载动画、中心播放键）
        Positioned.fill(
          child: IgnorePointer(
            ignoring: panState.kind == PlayerTipKind.none && !_isLoading && !_showCenterPlay,
            child: _buildCenterGroup(context),
          ),
        ),

        // 底部栏
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomBar(context),
        ),

        // HUD 隐藏时的底部 2px 细进度条
        if (isReady && !isOpening && !showHud && errorText.isEmpty && totalDuration.inMilliseconds > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(height: 2, color: Colors.white12),
                    Container(
                      height: 2,
                      width: constraints.maxWidth * _progressPercent,
                      color: AppTheme.accent,
                    ),
                  ],
                );
              },
            ),
          ),

        // 竖屏常驻返回按钮（无论正在加载/初始化/报错/HUD是否隐藏，持续存在且始终置顶可点击）
        if (!isFull && showBack)
          Positioned(
            left: 6,
            top: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0x33000000),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                ),
              ),
            ),
          ),

        // 错误提示层
        if (errorText.isNotEmpty)
          PlayerErrorPad(errorText: errorText, onRetry: onRetry, onCopyError: onCopyError),
      ],
    );
  }
}

