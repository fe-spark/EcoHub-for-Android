import 'package:flutter/material.dart';
import '../../common/app_theme.dart';
import '../../models/film_models.dart';

/// 现场播放页选集区：线路胶囊 + 剧集 + 简介
class LivePlayPanel extends StatelessWidget {
  final List<PlaySource> sources;
  final String playingSourceId;
  final int episodeIndex;
  final String plot;
  final void Function(String sourceId, int index) onSelectEpisode;

  const LivePlayPanel({
    super.key,
    required this.sources,
    required this.playingSourceId,
    required this.episodeIndex,
    this.plot = '',
    required this.onSelectEpisode,
  });

  PlaySource? get _playing {
    for (final source in sources) {
      if (source.id == playingSourceId) return source;
    }
    return sources.isNotEmpty ? sources.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final source = _playing;
    final episodes = source?.linkList ?? const <MovieUrlInfo>[];
    final intro = plot.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spaceLg, 0, AppTheme.spaceLg, AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sources.length > 1) ...[
            const _SectionTitle('线路'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in sources)
                  _Chip(
                    label: item.name,
                    active: item.id == playingSourceId,
                    onTap: () => onSelectEpisode(item.id, 0),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLg),
          ],
          const _SectionTitle('选集'),
          if (episodes.isEmpty)
            const Text('暂无剧集', style: TextStyle(fontSize: 13, color: AppTheme.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < episodes.length; i++)
                  _Chip(
                    label: episodes[i].episode.isNotEmpty ? episodes[i].episode : '第${i + 1}集',
                    active: source?.id == playingSourceId && i == episodeIndex,
                    onTap: () => onSelectEpisode(source!.id, i),
                  ),
              ],
            ),
          if (intro.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceLg),
            const _SectionTitle('剧情简介'),
            Text(
              intro,
              style: const TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTheme.accentSoft : AppTheme.bgChip,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: active ? AppTheme.accent : Colors.transparent),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppTheme.accent : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
