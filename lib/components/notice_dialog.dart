import 'package:flutter/material.dart';
import '../common/app_theme.dart';

/// 站点公告弹性弹窗
class NoticeDialog extends StatefulWidget {
  final String title;
  final String content;
  final VoidCallback onClose;

  const NoticeDialog({
    super.key,
    this.title = '站点公告',
    required this.content,
    required this.onClose,
  });

  @override
  State<NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends State<NoticeDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
          // 0.72 黑色遮罩
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleClose,
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) => Container(
                  color: Colors.black.withValues(alpha: 0.72 * _opacityAnimation.value),
                ),
              ),
            ),
          ),

          // 居中弹窗卡片
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Builder(
                builder: (context) {
                  final media = MediaQuery.of(context);
                  final landscape = media.size.height > 0 && media.size.height < 500;
                  final maxHeight = media.size.height * 0.88;

                  return Container(
                    width: media.size.width * 0.86,
                    constraints: BoxConstraints(maxWidth: 380, maxHeight: maxHeight),
                    padding: EdgeInsets.all(landscape ? AppTheme.spaceMd : AppTheme.spaceLg),
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.accentSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
                                size: 16,
                                color: AppTheme.accent,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSm),
                            Expanded(
                              child: Text(
                                widget.title.isNotEmpty ? widget.title : '站点公告',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                              onPressed: _handleClose,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                          ],
                        ),
                        SizedBox(height: landscape ? AppTheme.spaceSm : AppTheme.spaceMd),

                        // Content
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                widget.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: landscape ? AppTheme.spaceMd : AppTheme.spaceLg),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: landscape ? 38 : 42,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _handleClose,
                            child: const Text(
                              '我知道了',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
