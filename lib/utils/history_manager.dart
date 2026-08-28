import 'dart:convert';
import '../models/film_models.dart';
import 'server_config_manager.dart';

const String _keyHistory = 'film_history';
const int _maxHistory = 200;

/// 观看历史记录管理器（按源隔离）
class HistoryManager {
  static String _dataKey() {
    return ServerConfigManager.instance.scopedKey(_keyHistory);
  }

  static Future<HistoryItem?> find(String id) async {
    final map = await _readMap();
    return map[id];
  }

  static Future<List<HistoryItem>> list() async {
    final map = await _readMap();
    final items = map.values.toList();
    items.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return items;
  }

  static Future<void> save(HistoryItem item) async {
    final map = await _readMap();
    map[item.id] = item;
    final entries = map.values.toList();
    entries.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

    final trimmed = <String, HistoryItem>{};
    final limit = entries.length > _maxHistory ? _maxHistory : entries.length;
    for (var i = 0; i < limit; i++) {
      trimmed[entries[i].id] = entries[i];
    }
    await _writeMap(trimmed);
  }

  static Future<void> remove(String id) async {
    final map = await _readMap();
    map.remove(id);
    await _writeMap(map);
  }

  static Future<void> clear() async {
    await _writeMap({});
  }

  static Future<Map<String, HistoryItem>> _readMap() async {
    final key = _dataKey();
    if (key.isEmpty) return {};
    final pref = ServerConfigManager.instance.preferences;
    if (pref == null) await ServerConfigManager.instance.init();
    try {
      final raw = ServerConfigManager.instance.preferences?.getString(key) ?? '{}';
      final Map<String, dynamic> parsed = jsonDecode(raw);
      final result = <String, HistoryItem>{};
      parsed.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          result[k] = HistoryItem.fromJson(v);
        } else if (v is Map) {
          result[k] = HistoryItem.fromJson(v.map((ik, iv) => MapEntry('$ik', iv)));
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeMap(Map<String, HistoryItem> map) async {
    final key = _dataKey();
    if (key.isEmpty) return;
    final pref = ServerConfigManager.instance.preferences;
    if (pref == null) await ServerConfigManager.instance.init();
    try {
      final data = map.map((k, v) => MapEntry(k, v.toJson()));
      await ServerConfigManager.instance.preferences?.setString(key, jsonEncode(data));
    } catch (_) {}
  }
}
