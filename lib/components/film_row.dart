import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import 'film_card.dart';

/// 首页分类横向影片展示行
class FilmRow extends StatelessWidget {
  final String title;
  final List<MovieBasicInfo> films;
  final String moreText;
  final int pid;
  final VoidCallback? onMore;

  const FilmRow({
    super.key,
    required this.title,
    required this.films,
    this.moreText = '查看全部',
    this.pid = 0,
    this.onMore,
  });

  void _openMore(BuildContext context) {
    if (onMore != null) {
      onMore!();
    } else if (pid > 0) {
      Navigator.pushNamed(context, '/filter', arguments: {'Pid': '$pid'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceSm,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMore(context),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openMore(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        moreText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppTheme.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          if (films.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: Text(
                '暂无影片',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                itemCount: films.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppTheme.spaceSm),
                itemBuilder: (context, index) {
                  return FilmCard(
                    film: films[index],
                    cardWidth: 108,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
