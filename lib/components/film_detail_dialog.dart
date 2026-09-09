import 'package:flutter/material.dart';
import '../common/app_theme.dart';

/// 播放页底部详情弹层，对齐 OHOS `FilmDetailDialog`
class FilmDetailDialog extends StatelessWidget {
  final String name;
  final String scoreText;
  final List<String> tags;
  final String director;
  final String actor;
  final String plot;

  const FilmDetailDialog({
    super.key,
    required this.name,
    this.scoreText = '',
    this.tags = const [],
    this.director = '',
    this.actor = '',
    this.plot = '',
  });

  static Future<void> show(
    BuildContext context, {
    required String name,
    String scoreText = '',
    List<String> tags = const [],
    String director = '',
    String actor = '',
    String plot = '',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xA6000000),
      builder: (ctx) => FilmDetailDialog(
        name: name,
        scoreText: scoreText,
        tags: tags,
        director: director,
        actor: actor,
        plot: plot,
      ),
    );
  }

  Widget _section(String title, String body, {Color bodyColor = AppTheme.textPrimary}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0x0FFFFFFF), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(fontSize: 13, height: title == '剧情简介' ? 1.7 : 1.55, color: bodyColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final landscape = media.size.height > 0 && media.size.height < 500;
    final bottom = media.padding.bottom < 16 ? 16.0 : media.padding.bottom;
    final scrollMax = landscape ? 150.0 : media.size.height * 0.5;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: media.size.height * 0.88),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 4, 16, bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF181A22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x38FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.article_outlined, size: 18, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  const Text('详细信息', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0x14FFFFFF), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, 12, 12, tags.isNotEmpty ? 6 : 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: const Color(0x0FFFFFFF), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        if (scoreText.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentSoft,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              '★ $scoreText 分',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accent),
                            ),
                          ),
                      ],
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgChip,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: Text(tag, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: scrollMax),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (director.isNotEmpty) _section('导演', director),
                      if (director.isNotEmpty && actor.isNotEmpty) const SizedBox(height: 10),
                      if (actor.isNotEmpty) _section('主演', actor),
                      if ((director.isNotEmpty || actor.isNotEmpty) && plot.isNotEmpty) const SizedBox(height: 10),
                      if (plot.isNotEmpty) _section('剧情简介', plot, bodyColor: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              SizedBox(height: landscape ? 8 : 12),
              SizedBox(
                width: double.infinity,
                height: landscape ? 36 : 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('我知道了', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
