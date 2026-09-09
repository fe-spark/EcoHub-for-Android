import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../models/film_models.dart';
import '../../utils/favorite_manager.dart';
import '../film_detail_dialog.dart';

/// 播放页影片详情头部，对齐 OHOS `FilmDetailHeader`
class FilmDetailHeader extends StatefulWidget {
  final String filmId;
  final String picture;
  final String name;
  final String subTitle;
  final String actor;
  final String plot;
  final MovieDescriptor? descriptor;

  const FilmDetailHeader({
    super.key,
    required this.filmId,
    this.picture = '',
    required this.name,
    this.subTitle = '',
    this.actor = '',
    this.plot = '',
    this.descriptor,
  });

  @override
  State<FilmDetailHeader> createState() => _FilmDetailHeaderState();
}

class _FilmDetailHeaderState extends State<FilmDetailHeader> {
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    FavoriteManager.onFavoriteChange(_syncFav);
    _syncFav();
  }

  @override
  void didUpdateWidget(covariant FilmDetailHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filmId != widget.filmId) {
      _syncFav();
    }
  }

  @override
  void dispose() {
    FavoriteManager.offFavoriteChange(_syncFav);
    super.dispose();
  }

  Future<void> _syncFav() async {
    final id = widget.filmId;
    if (id.isEmpty) {
      if (mounted) setState(() => _isFav = false);
      return;
    }
    final fav = await FavoriteManager.isFavorite(id);
    if (mounted && widget.filmId == id) {
      setState(() => _isFav = fav);
    }
  }

  String _scoreText() {
    final s = widget.descriptor?.dbScore.trim() ?? '';
    if (s.isEmpty || s == '0' || s == '0.0') return '';
    return s;
  }

  String _cleanPlot() {
    final raw = widget.plot.isNotEmpty
        ? widget.plot
        : (widget.descriptor?.content.isNotEmpty == true
            ? widget.descriptor!.content
            : (widget.descriptor?.blurb ?? ''));
    return raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  List<String> _metaTags() {
    final tags = <String>[];
    final year = widget.descriptor?.year.trim() ?? '';
    if (year.isNotEmpty) tags.add(year);
    final cat = (widget.descriptor?.classTag.isNotEmpty == true)
        ? widget.descriptor!.classTag
        : (widget.descriptor?.cName ?? '');
    if (cat.trim().isNotEmpty) {
      for (final part in cat.trim().split(RegExp(r'[,/，\s]+'))) {
        final p = part.trim();
        if (p.isNotEmpty && !tags.contains(p) && tags.length < 5) tags.add(p);
      }
    }
    final area = widget.descriptor?.area.trim() ?? '';
    if (area.isNotEmpty && !tags.contains(area)) tags.add(area);
    final lang = widget.descriptor?.language.trim() ?? '';
    if (lang.isNotEmpty && !tags.contains(lang)) tags.add(lang);
    return tags;
  }

  String _directorText() {
    final raw = widget.descriptor?.director.trim() ?? '';
    if (raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'\s*[，,、]\s*'), ' / ');
  }

  String _actorText() {
    final raw = (widget.descriptor?.actor.isNotEmpty == true)
        ? widget.descriptor!.actor.trim()
        : widget.actor.trim();
    if (raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'\s*[，,、]\s*'), ' / ');
  }

  bool _hasDetailInfo() {
    return _directorText().isNotEmpty || _actorText().isNotEmpty || _cleanPlot().isNotEmpty;
  }

  String _snippet() {
    final actor = _actorText();
    if (actor.isNotEmpty) return '主演：$actor';
    final director = _directorText();
    if (director.isNotEmpty) return '导演：$director';
    final plot = _cleanPlot();
    if (plot.isNotEmpty) return '简介：${plot.replaceAll(RegExp(r'\n+'), ' ')}';
    return '查看简介 / 主演 / 导演';
  }

  Future<void> _toggleFavorite() async {
    if (widget.filmId.isEmpty || widget.name.isEmpty) return;
    final desc = widget.descriptor;
    final next = await FavoriteManager.toggle(FavoriteItem(
      id: widget.filmId,
      name: widget.name,
      picture: widget.picture,
      cName: desc?.cName ?? '',
      remarks: desc?.remarks ?? '',
      year: desc?.year ?? '',
      area: desc?.area ?? '',
      subTitle: widget.subTitle,
      actor: widget.actor,
      director: desc?.director ?? '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    if (!mounted) return;
    setState(() => _isFav = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next ? '已加入收藏' : '已取消收藏')),
    );
  }

  void _openDialog() {
    FilmDetailDialog.show(
      context,
      name: widget.name,
      scoreText: _scoreText(),
      tags: _metaTags(),
      director: _directorText(),
      actor: _actorText(),
      plot: _cleanPlot(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = _scoreText();
    final tags = _metaTags();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    widget.name,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _toggleFavorite,
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                    decoration: BoxDecoration(
                      color: _isFav ? const Color(0x1FFA8C16) : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        width: 0.5,
                        color: _isFav ? const Color(0x4DFA8C16) : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 13,
                          color: _isFav ? AppTheme.accent : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isFav ? '已收藏' : '收藏',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _isFav ? AppTheme.accent : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                  decoration: BoxDecoration(
                    color: score.isNotEmpty ? AppTheme.accentSoft : AppTheme.bgChip,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    score.isNotEmpty ? '★ $score 分' : '★ 暂无评分',
                    style: TextStyle(
                      fontSize: score.isNotEmpty ? 12 : 11,
                      fontWeight: FontWeight.bold,
                      color: score.isNotEmpty ? AppTheme.accent : AppTheme.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tags
                          .map(
                            (tag) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.bgChip,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Text(tag, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasDetailInfo())
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: InkWell(
                onTap: _openDialog,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.article_outlined, size: 14, color: AppTheme.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _snippet(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(6, 3, 4, 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentSoft,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('详情', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                            Icon(Icons.chevron_right_rounded, size: 12, color: AppTheme.accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
