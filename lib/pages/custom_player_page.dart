import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/app_theme.dart';
import '../components/page_header.dart';
import '../components/player/video_player_widget.dart';

/// 自定义播放页面
class CustomPlayerPage extends StatefulWidget {
  const CustomPlayerPage({super.key});

  @override
  State<CustomPlayerPage> createState() => _CustomPlayerPageState();
}

class _CustomPlayerPageState extends State<CustomPlayerPage> {
  final TextEditingController _inputController = TextEditingController();
  String _playUrl = '';
  int _reloadToken = 0;
  bool _isFull = false;

  @override
  void dispose() {
    _inputController.dispose();
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}
    super.dispose();
  }

  void _setFullscreen(bool full) {
    if (_isFull == full) return;
    setState(() {
      _isFull = full;
    });
    try {
      if (full) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } catch (_) {}
  }

  void _play() {
    FocusScope.of(context).unfocus();
    final url = _inputController.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入正确的 mp4 或 m3u8 地址')),
      );
      return;
    }
    setState(() {
      _playUrl = url;
      _reloadToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isFullMode = _isFull || isLandscape;

    return PopScope(
      canPop: !isFullMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isFullMode) {
          _setFullscreen(false);
        }
      },
      child: Scaffold(
        backgroundColor: isFullMode ? Colors.black : AppTheme.bg,
        body: SafeArea(
          top: !isFullMode,
          bottom: !isFullMode,
          left: false,
          right: false,
          child: Column(
            children: [
              if (!isFullMode) ...[
                const PageHeader(title: '自定义播放'),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 18, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: '输入 mp4 或 m3u8 播放地址',
                                    hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  textInputAction: TextInputAction.go,
                                  onSubmitted: (_) => _play(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: _play,
                        child: const Row(
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 18),
                            SizedBox(width: 2),
                            Text('播放', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Video Player
              if (isFullMode)
                Expanded(
                  child: VideoPlayerWidget(
                    key: const ValueKey('custom_video_player'),
                    videoUrl: _playUrl,
                    title: '自定义播放',
                    showBack: true,
                    isFull: true,
                    reloadToken: _reloadToken,
                    onBack: () => _setFullscreen(false),
                    onFullscreenChange: _setFullscreen,
                  ),
                )
              else
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoPlayerWidget(
                    key: const ValueKey('custom_video_player'),
                    videoUrl: _playUrl,
                    title: '自定义播放',
                    showBack: false,
                    isFull: false,
                    reloadToken: _reloadToken,
                    onFullscreenChange: _setFullscreen,
                  ),
                ),

              if (!isFullMode) ...[
                const Padding(
                  padding: EdgeInsets.all(AppTheme.spaceLg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '仅支持直链 mp4 / m3u8，不会写入观看历史。',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
