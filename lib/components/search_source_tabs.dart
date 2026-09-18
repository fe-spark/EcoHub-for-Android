import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';

class SearchSourceTabs extends StatelessWidget {
  final List<SearchSourceTab> sources;
  final String activeId;
  final ValueChanged<String> onChange;

  const SearchSourceTabs({
    super.key,
    required this.sources,
    required this.activeId,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    if (sources.length <= 1) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
        itemBuilder: (context, index) {
          final tab = sources[index];
          final active = tab.id == activeId;
          final metaColor = active ? Colors.white : AppTheme.textSecondary;
          return ChoiceChip(
            key: ValueKey('${tab.id}_${tab.loading}_${tab.count}'),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tab.name),
                const SizedBox(width: 4),
                if (tab.loading)
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: metaColor,
                    ),
                  )
                else
                  Text('${tab.count}'),
              ],
            ),
            selected: active,
            onSelected: (_) => onChange(tab.id),
            selectedColor: AppTheme.accent,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: metaColor,
            ),
            backgroundColor: AppTheme.bgCard,
            shape: const StadiumBorder(),
            side: BorderSide.none,
            showCheckmark: false,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: sources.length,
      ),
    );
  }
}
