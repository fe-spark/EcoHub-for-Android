import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'player_scale.dart';
import '../../utils/format_util.dart';

/// 播放器视频渲染画面与海报层，对齐 OHOS `PlayerVideoLayer.ets`
class PlayerVideoSurface extends StatelessWidget {
  final VideoPlayerController? controller;
  final PlayerScaleMode scaleMode;
  final String poster;
  final bool isOpening;
  final bool isReady;

  const PlayerVideoSurface({
    super.key,
    required this.controller,
    required this.scaleMode,
    required this.poster,
    this.isOpening = false,
    this.isReady = false,
  });

  /// 视频实际宽高比（已按旋转校正）；未初始化或尺寸未知时返回 null
  static double? videoAspect(VideoPlayerController? c) {
    if (c == null || !c.value.isInitialized) return null;
    final size = c.value.size;
    final rot = c.value.rotationCorrection;
    final isRotated = rot == 90 || rot == 270;
    final w = isRotated ? size.height : size.width;
    final h = isRotated ? size.width : size.height;
    if (w > 0 && h > 0) return w / h;
    final a = c.value.aspectRatio;
    return a > 0 && a.isFinite ? a : null;
  }

  /// 视频画面在播放器 [box] 内实际显示的矩形（弹幕层按它定位和裁剪）：
  /// 适应模式按宽高比居中、留黑边部分不算画面；填充 / 拉伸铺满整个播放器；宽高比未知时按整个播放器。
  static Rect displayRect(Size box, double? aspect, PlayerScaleMode mode) {
    final full = Offset.zero & box;
    if (mode != PlayerScaleMode.fit || aspect == null || aspect <= 0 || box.width <= 0 || box.height <= 0) {
      return full;
    }
    double w = box.width;
    double h = w / aspect;
    if (h > box.height) {
      h = box.height;
      w = h * aspect;
    }
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  Widget _buildVideo(VideoPlayerController c) {
    final size = c.value.size;
    final rot = c.value.rotationCorrection;
    final isRotated = rot == 90 || rot == 270;
    final w = isRotated ? size.height : size.width;
    final h = isRotated ? size.width : size.height;
    final effectiveW = w > 0 ? w : 16.0;
    final effectiveH = h > 0 ? h : 9.0;
    final aspect = (w > 0 && h > 0) ? (w / h) : (c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9);
    if (scaleMode == PlayerScaleMode.fit) {
      return Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: VideoPlayer(c, key: ValueKey(c)),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: PlayerScale.boxFit(scaleMode),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: effectiveW,
          height: effectiveH,
          child: VideoPlayer(c, key: ValueKey(c)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final hasInitializedVideo = c != null && c.value.isInitialized;
    // 画面活跃中（已在播放或已有有效帧进度）时强制隐藏海报，避免视频画面透出与海报并存
    final isVideoActive = hasInitializedVideo && (c.value.isPlaying || c.value.position > Duration.zero);
    // 对齐 OHOS `if (this.poster && (!this.ready || this.opening))`：未就绪或打开中展示完整封面
    final showPoster = poster.isNotEmpty &&
        !isVideoActive &&
        (!isReady || isOpening || !hasInitializedVideo);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasInitializedVideo)
            _buildVideo(c),
          if (showPoster)
            Positioned.fill(
              child: Container(
                color: Colors.black, // 对齐 OHOS PlayerVideoLayer.BG_COLOR：纯黑底色阻断底层画面漏光
                alignment: Alignment.center,
                child: Image.network(
                  poster,
                  headers: FormatUtil.imageHeaders(poster),
                  fit: BoxFit.contain, // 对齐 OHOS ImageFit.Contain：完整展示不裁切
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
