import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../utils/server_config_manager.dart';
import '../utils/source_guard.dart';
import '../utils/app_version_util.dart';

class ApiResponse {
  final int code;
  final String msg;
  final dynamic data;

  ApiResponse({
    required this.code,
    required this.msg,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      code: json['code'] is int ? json['code'] : (int.tryParse('${json['code']}') ?? -1),
      msg: '${json['msg'] ?? ''}',
      data: json['data'],
    );
  }
}

class ConnectionResult {
  final bool ok;
  final String? message;
  final bool isPrivate;

  const ConnectionResult({
    required this.ok,
    this.message,
    this.isPrivate = false,
  });
}

/// HTTP 客户端单例
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  String _userAgent = '';

  factory HttpClient() => _instance;
  static HttpClient get instance => _instance;

  HttpClient._internal();

  Future<String> _resolveUserAgent() async {
    if (_userAgent.isNotEmpty) return _userAgent;
    try {
      final version = await AppVersionUtil.getVersionName();
      _userAgent = version.isNotEmpty ? 'EcoHub-App/$version' : 'EcoHub-App';
    } catch (_) {
      _userAgent = 'EcoHub-App';
    }
    return _userAgent;
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? params,
    int timeoutMs = 15000,
  }) async {
    final manager = ServerConfigManager.instance;
    String url;
    try {
      url = manager.buildApiUrl(path);
    } catch (e) {
      SourceGuard.intercept();
      rethrow;
    }

    if (params != null && params.isNotEmpty) {
      final queryPairs = <String>[];
      params.forEach((k, v) {
        if (v != null && '$v'.trim().isNotEmpty) {
          queryPairs.add('${Uri.encodeComponent(k)}=${Uri.encodeComponent('$v')}');
        }
      });
      if (queryPairs.isNotEmpty) {
        url += (url.contains('?') ? '&' : '?') + queryPairs.join('&');
      }
    }

    return _send(url, timeoutMs);
  }

  void trackView(String action, [String resource = '', String page = '', String deviceModel = '']) {
    _sendTrack(action, resource, page, deviceModel).catchError((_) {});
  }

  Future<void> _sendTrack(String action, String resource, String page, String deviceModel) async {
    final manager = ServerConfigManager.instance;
    String url;
    try {
      url = manager.buildApiUrl('/stat/view');
    } catch (_) {
      return;
    }
    final userAgent = await _resolveUserAgent();
    String version = '';
    try {
      version = await AppVersionUtil.getVersionName();
    } catch (_) {}

    final source = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'app');
    String deviceId = '';
    try {
      deviceId = await manager.getDeviceId();
    } catch (_) {}
    final resolvedModel = deviceModel.trim().isNotEmpty
        ? deviceModel.trim()
        : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'.trim();

    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': userAgent,
          if (deviceId.isNotEmpty) 'X-Device-Id': deviceId,
          if (deviceId.isNotEmpty) 'Device-Id': deviceId,
        },
        body: jsonEncode({
          'source': source,
          'action': action,
          'resource': resource,
          'page': page.isNotEmpty ? page : action,
          'app_version': version,
          'device_model': resolvedModel,
          'device_id': deviceId,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<ConnectionResult> testConnection(String baseUrl) async {
    final raw = baseUrl.trim();
    if (raw.isEmpty) {
      return const ConnectionResult(ok: false, message: '请输入有效的软件源地址');
    }
    final manager = ServerConfigManager.instance;
    final origin = ServerConfigManager.stripApiSuffix(manager.normalizeRaw(baseUrl));
    if (origin.isEmpty || origin == 'https://' || origin == 'http://') {
      return const ConnectionResult(ok: false, message: '请输入有效的软件源地址');
    }

    final key = ServerConfigManager.extractProvideKey(baseUrl);
    SourceGuard.beginSkip();
    try {
      final query = key.isNotEmpty ? '?key=${Uri.encodeComponent(key)}' : '';
      // 优先探测专有端点 /api/provide/app，可直接检验私有化与订阅密钥
      try {
        final response = await _send('$origin/api/provide/app$query', 5000, customKey: key);
        if (response.code == 1 || response.code == 0) {
          return const ConnectionResult(ok: true);
        }
      } catch (appErr) {
        final msg = appErr.toString().replaceFirst('Exception: ', '');
        if (msg.contains('私有化') || msg.contains('订阅密钥')) {
          return ConnectionResult(ok: false, isPrivate: true, message: msg);
        }
        if (msg.contains('401') || msg.contains('403')) {
          return const ConnectionResult(ok: false, isPrivate: true, message: '该软件源已开启私有化访问，请在地址后追加 ?key=密钥');
        }
        // 过渡兼容逻辑：若 404 说明为早期未支持 /api/provide/app 的旧版服务端，尝试兜底探测 /api/health。
        // 注意：服务端 /api/health 未来大版本将废弃移除，届时将仅支持 /api/provide/app 探测。
        if (msg.contains('404')) {
          final healthRes = await _send('$origin/api/health$query', 5000, customKey: key);
          if (healthRes.code == 0) {
            return const ConnectionResult(ok: true);
          }
        }
        rethrow;
      }
      return const ConnectionResult(ok: true);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      return ConnectionResult(ok: false, message: msg.isNotEmpty ? msg : '无法连接该源，请检查地址或网络');
    } finally {
      SourceGuard.endSkip();
    }
  }

  Future<ApiResponse> _send(String url, int timeoutMs, {String? customKey}) async {
    final userAgent = await _resolveUserAgent();
    final manager = ServerConfigManager.instance;
    String deviceId = '';
    try {
      deviceId = await manager.getDeviceId();
    } catch (_) {}
    final key = customKey ?? (manager.provideKey.isNotEmpty ? manager.provideKey : null);
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': userAgent,
          if (deviceId.isNotEmpty) 'X-Device-Id': deviceId,
          if (deviceId.isNotEmpty) 'Device-Id': deviceId,
          if (key != null && key.isNotEmpty) 'X-Provide-Key': key,
        },
      ).timeout(Duration(milliseconds: timeoutMs));

      if (res.statusCode != 200) {
        String errMsg = 'HTTP ${res.statusCode}';
        try {
          final body = jsonDecode(utf8.decode(res.bodyBytes));
          if (body is Map && body['msg'] != null && body['msg'].toString().isNotEmpty) {
            errMsg = body['msg'].toString();
          }
        } catch (_) {}
        throw Exception(errMsg);
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map<String, dynamic>) {
        return ApiResponse.fromJson(body);
      } else if (body is Map) {
        return ApiResponse.fromJson(body.map((k, v) => MapEntry('$k', v)));
      }
      throw Exception('响应格式错误');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('网络请求失败');
    }
  }
}
