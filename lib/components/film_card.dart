import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../utils/format_util.dart';
import '../utils/server_config_manager.dart';

/// 影片海报卡片组件
class FilmCard extends StatelessWidget {
  final MovieBasicInfo film;
  final double? cardWidth;
  final bool showMeta;
  final void Function(MovieBasicInfo film)? onClickCard;

  const FilmCard({
    super.key,
    required this.film,
    this.cardWidth,
    this.showMeta = true,
    this.onClickCard,
  });

  String _resolvedPosterUrl() {
    final raw = FormatUtil.poster(film);
    return ServerConfigManager.instance.resolveMediaUrl(raw);
  }

  void _handleClick(BuildContext context) {
    if (onClickCard != null) {
      onClickCard!(film);
      return;
    }
    final filmId = FormatUtil.filmId(film);
    Navigator.pushNamed(context, '/play', arguments: {'id': filmId});
  }

  Widget _buildPosterTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xB8141224),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = _resolvedPosterUrl();

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (posterUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.bgCard,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                else
                  _buildPlaceholder(),

                // 底部渐变蒙层
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.55, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),

                // 标签层
                Positioned(
                  left: 6,
                  right: 6,
                  top: 6,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (film.year.isNotEmpty) _buildPosterTag(film.year),
                      if (film.cName.isNotEmpty) _buildPosterTag(film.cName),
                      if (film.remarks.isNotEmpty) _buildPosterTag(film.remarks),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showMeta) ...[
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            film.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            film.subTitle.isNotEmpty ? film.subTitle : ' ',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return InkWell(
      onTap: () => _handleClick(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: cardWidth != null ? SizedBox(width: cardWidth, child: card) : card,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.bgCard,
      child: Center(
        child: Text(
          film.name.isNotEmpty ? film.name.substring(0, 1) : '影',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
