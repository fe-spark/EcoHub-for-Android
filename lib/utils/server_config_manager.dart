import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyServerUrl = 'server_base_url';
const String _keyServerHistory = 'server_url_history';
const String _keyDeviceId = 'device_unique_id';
const int _maxServerHistory = 10;

/// 软件源配置管理器
class ServerConfigManager {
  static final ServerConfigManager _instance = ServerConfigManager._internal();
  SharedPreferences? _pref;
  String _cachedUrl = '';
  String _cachedDeviceId = '';

  factory ServerConfigManager() => _instance;
  static ServerConfigManager get instance => _instance;

  ServerConfigManager._internal();

  Future<void> init() async {
    try {
      _pref = await SharedPreferences.getInstance();
      _cachedUrl = _pref?.getString(_keyServerUrl) ?? '';
    } catch (_) {}
  }

  SharedPreferences? get preferences => _pref;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId.isNotEmpty) return _cachedDeviceId;
    if (_pref == null) await init();
    var id = _pref?.getString(_keyDeviceId) ?? '';
    if (id.isEmpty) {
      final rand = Random().nextInt(1 << 32).toRadixString(36);
      id = 'and_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}_$rand';
      await _pref?.setString(_keyDeviceId, id);
    }
    _cachedDeviceId = id;
    return id;
  }

  Future<String> getServerUrl() async {
    if (_cachedUrl.isNotEmpty) return _cachedUrl;
    if (_pref == null) await init();
    _cachedUrl = _pref?.getString(_keyServerUrl) ?? '';
    return _cachedUrl;
  }

  String getCachedServerUrl() => _cachedUrl;

  String getOrigin() {
    if (_cachedUrl.trim().isEmpty) return '';
    return stripApiSuffix(normalizeRaw(_cachedUrl));
  }

  String storageScope() {
    return hostScope(getOrigin());
  }

  String scopedKey(String name) {
    final scope = storageScope();
    if (scope.isEmpty) return '';
    return '$name@$scope';
  }

  static String hostScope(String origin) {
    var value = origin.trim().toLowerCase();
    if (value.isEmpty) return '';
    if (value.startsWith('https://')) {
      value = value.substring(8);
    } else if (value.startsWith('http://')) {
      value = value.substring(7);
    }
    final slash = value.indexOf('/');
    if (slash >= 0) {
      value = value.substring(0, slash);
    }
    return value;
  }

  String getApiBase() {
    final origin = getOrigin();
    return origin.isNotEmpty ? '$origin/api' : '';
  }

  String resolveMediaUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final origin = getOrigin();
    if (origin.isEmpty) return path;
    return path.startsWith('/') ? '$origin$path' : '$origin/$path';
  }

  Future<List<String>> getServerHistory() async {
    if (_pref == null) await init();
    try {
      final raw = _pref?.getString(_keyServerHistory) ?? '[]';
      final list = (jsonDecode(raw) as List).map((e) => '$e').toList();
      if (list.isNotEmpty) return list;
      if (_cachedUrl.isNotEmpty) return [_cachedUrl];
      return [];
    } catch (_) {
      return _cachedUrl.isNotEmpty ? [_cachedUrl] : [];
    }
  }

  Future<void> addServerHistory(String url) async {
    final cleanUrl = normalizeRaw(url);
    if (cleanUrl.isEmpty) return;
    if (_pref == null) await init();
    try {
      final current = await getServerHistory();
      final filtered = current.where((item) => item != cleanUrl).toList();
      filtered.insert(0, cleanUrl);
      if (filtered.length > _maxServerHistory) {
        filtered.removeRange(_maxServerHistory, filtered.length);
      }
      await _pref?.setString(_keyServerHistory, jsonEncode(filtered));
    } catch (_) {}
  }

  Future<void> removeServerHistory(String url) async {
    if (_pref == null) await init();
    try {
      final current = await getServerHistory();
      final filtered = current.where((item) => item != url).toList();
      await _pref?.setString(_keyServerHistory, jsonEncode(filtered));
    } catch (_) {}
  }

  Future<void> clearServerHistory() async {
    if (_pref == null) await init();
    try {
      await _pref?.setString(_keyServerHistory, '[]');
    } catch (_) {}
  }

  Future<void> setServerUrl(String url) async {
    final cleanUrl = normalizeRaw(url);
    _cachedUrl = cleanUrl;
    if (_pref == null) await init();
    await _pref?.setString(_keyServerUrl, cleanUrl);
    await addServerHistory(cleanUrl);
  }

  Future<void> clearServerUrl() async {
    _cachedUrl = '';
    if (_pref == null) await init();
    await _pref?.remove(_keyServerUrl);
  }

  String normalizeRaw(String url) {
    var cleanUrl = url.trim();
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    return cleanUrl;
  }

  static String stripApiSuffix(String url) {
    var base = url.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    while (base.toLowerCase().endsWith('/api')) {
      base = base.substring(0, base.length - 4);
      while (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
    }
    return base;
  }

  String buildApiUrl(String path) {
    final apiBase = getApiBase();
    if (apiBase.isEmpty) {
      throw Exception('未配置软件源');
    }
    final apiPath = path.startsWith('/') ? path : '/$path';
    return '$apiBase$apiPath';
  }
}
