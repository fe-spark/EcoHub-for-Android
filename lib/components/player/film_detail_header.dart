import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../models/film_models.dart';

/// 播放页影片详情头部
class FilmDetailHeader extends StatefulWidget {
  final String name;
  final String actor;
  final String plot;
  final MovieDescriptor? descriptor;

  const FilmDetailHeader({
    super.key,
    required this.name,
    this.actor = '',
    this.plot = '',
    this.descriptor,
  });

  @override
  State<FilmDetailHeader> createState() => _FilmDetailHeaderState();
}

class _FilmDetailHeaderState extends State<FilmDetailHeader> {
  bool _plotOpen = false;

  String _scoreText() {
    final s = widget.descriptor?.dbScore.trim() ?? '';
    if (s.isEmpty || s == '0' || s == '0.0') return '';
    return s;
  }

  String _metaTagsText() {
    final tags = <String>[];
    if (widget.descriptor?.year.trim().isNotEmpty ?? false) {
      tags.add(widget.descriptor!.year.trim());
    }
    final cat = (widget.descriptor?.classTag.isNotEmpty ?? false)
        ? widget.descriptor!.classTag
        : (widget.descriptor?.cName ?? '');
    if (cat.trim().isNotEmpty) {
      tags.add(cat.trim().replaceAll(RegExp(r'\s*[,/，]\s*'), ' / '));
    }
    if (widget.descriptor?.area.trim().isNotEmpty ?? false) {
      tags.add(widget.descriptor!.area.trim());
    }
    if (widget.descriptor?.remarks.trim().isNotEmpty ?? false) {
      tags.add(widget.descriptor!.remarks.trim());
    } else if (widget.descriptor?.state.trim().isNotEmpty ?? false) {
      tags.add(widget.descriptor!.state.trim());
    }
    return tags.join('  ·  ');
  }

  String _directorText() {
    final raw = widget.descriptor?.director.trim() ?? '';
    if (raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'\s*[，,、]\s*'), ' / ');
  }

  String _actorText() {
    final raw = (widget.descriptor?.actor.isNotEmpty ?? false)
        ? widget.descriptor!.actor.trim()
        : widget.actor.trim();
    if (raw.isEmpty) return '';
    return raw.replaceAll(RegExp(r'\s*[，,、]\s*'), ' / ');
  }

  String _plotText() {
    final raw = widget.plot.isNotEmpty
        ? widget.plot
        : (widget.descriptor?.content.isNotEmpty ?? false
            ? widget.descriptor!.content
            : (widget.descriptor?.blurb ?? ''));
    final text = raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return text.isNotEmpty ? text : '暂无介绍';
  }

  @override
  Widget build(BuildContext context) {
    final score = _scoreText();
    final meta = _metaTagsText();
    final director = _directorText();
    final actor = _actorText();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (score.isNotEmpty) ...[
                const SizedBox(width: AppTheme.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '★ ',
                        style: TextStyle(fontSize: 11, color: AppTheme.accent),
                      ),
                      Text(
                        score,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Meta tags
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Director & Actor
          if (director.isNotEmpty || actor.isNotEmpty) ...[
            const SizedBox(height: 6),
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontSize: 12),
                children: [
                  if (director.isNotEmpty) ...[
                    const TextSpan(text: '导演: ', style: TextStyle(color: AppTheme.textMuted)),
                    TextSpan(
                      text: '$director${actor.isNotEmpty ? "    " : ""}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  if (actor.isNotEmpty) ...[
                    const TextSpan(text: '主演: ', style: TextStyle(color: AppTheme.textMuted)),
                    TextSpan(
                      text: actor,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Plot
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: _plotOpen ? CrossAxisAlignment.end : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 150),
                  crossFadeState: _plotOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: Text(
                    _plotText(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(
                    _plotText(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _plotOpen = !_plotOpen;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _plotOpen ? '收起' : '简介',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      _plotOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppTheme.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
