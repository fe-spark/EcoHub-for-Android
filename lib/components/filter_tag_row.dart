import 'package:flutter/material.dart';
import '../common/app_theme.dart';

/// 筛选标签行组件
class FilterTagRow extends StatelessWidget {
  final String filterKey;
  final String title;
  final List<String> names;
  final List<String> values;
  final String selected;
  final void Function(String key, String value) onPick;

  const FilterTagRow({
    super.key,
    required this.filterKey,
    required this.title,
    required this.names,
    required this.values,
    required this.selected,
    required this.onPick,
  });

  bool _isSelected(String val) {
    if (filterKey == 'Sort' && (selected.isEmpty || selected == 'update_stamp')) {
      return val == 'update_stamp';
    }
    return selected == val;
  }

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.only(left: AppTheme.spaceMd),
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSm),
              child: Row(
                children: List.generate(names.length, (index) {
                  final name = names[index];
                  final val = index < values.length ? values[index] : name;
                  final active = _isSelected(val);

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => onPick(filterKey, val),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                            color: active ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
