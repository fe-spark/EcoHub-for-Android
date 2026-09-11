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

  Widget _buildVideo(VideoPlayerController c) {
    final size = c.value.size;
    final w = size.width > 0 ? size.width : 16.0;
    final h = size.height > 0 ? size.height : 9.0;
    if (scaleMode == PlayerScaleMode.fit) {
      return Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
          child: VideoPlayer(c, key: ValueKey(c)),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: PlayerScale.boxFit(scaleMode),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: w,
          height: h,
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
