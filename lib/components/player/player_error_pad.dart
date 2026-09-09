import 'package:flutter/material.dart';
import '../../common/app_theme.dart';

/// 播放失败覆盖层
class PlayerErrorPad extends StatelessWidget {
  final String errorText;
  final VoidCallback onRetry;
  final VoidCallback? onCopyError;

  const PlayerErrorPad({
    super.key,
    required this.errorText,
    required this.onRetry,
    this.onCopyError,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xD9000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('播放异常', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              errorText.isNotEmpty ? errorText : '视频无法播放，请重试！',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: onRetry,
                  child: const Text('重新播放', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                if (onCopyError != null) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: onCopyError,
                    child: const Text('复制错误', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
