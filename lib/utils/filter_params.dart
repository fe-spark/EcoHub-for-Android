/// v2 `/filmClassifySearch` 的筛选回写和标签行用 Category、Plot、Area、Language、Year、Sort。
/// v3 `/films/filter` 把同一维回写成 category、plot、area、language、year、sort。
/// 两端混在一次请求里时，服务端会先读到旧的小写值，类型怎么选列表都不变。
class FilterParams {
  static const _canonical = <String, String>{
    'category': 'Category',
    'cid': 'Category',
    'plot': 'Plot',
    'area': 'Area',
    'language': 'Language',
    'year': 'Year',
    'sort': 'Sort',
    'pid': 'Pid',
  };

  static String canonical(String key) {
    return _canonical[key] ?? _canonical[key.toLowerCase()] ?? key;
  }

  static bool isPid(String key) => canonical(key) == 'Pid';

  /// 已选条件收成标签行的键。同一维已有规范键时，别名不能覆盖它。
  static Map<String, String> fold(Map<String, String> selected) {
    final out = <String, String>{};
    selected.forEach((raw, value) {
      if (isPid(raw)) return;
      final text = value.trim();
      if (text.isEmpty) return;
      final key = canonical(raw);
      if (!out.containsKey(key) || raw == key) {
        out[key] = text;
      }
    });
    return out;
  }

  /// 把接口回写并进已选条件。空值表示这一维取消。Pid 不是筛选项。
  static Map<String, String> applyEcho(
    Map<String, String> selected,
    List<String> keys,
    List<String> values,
  ) {
    final next = fold(selected);
    for (var i = 0; i < keys.length; i++) {
      final raw = keys[i];
      if (isPid(raw)) continue;
      final key = canonical(raw);
      final text = (i < values.length ? values[i] : '').trim();
      if (text.isEmpty) {
        next.remove(key);
      } else {
        next[key] = text;
      }
    }
    return next;
  }
}
