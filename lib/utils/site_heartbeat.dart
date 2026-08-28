import 'dart:async';
import '../api/film_api.dart';
import 'server_config_manager.dart';
import 'source_guard.dart';

const int _heartbeatIntervalMs = 10000;
const int _maxFailures = 3;

/// 站点前台心跳探活管理器
class SiteHeartbeat {
  static final SiteHeartbeat _instance = SiteHeartbeat._internal();
  bool _running = false;
  bool _probing = false;
  Timer? _timer;
  int _consecutiveFailures = 0;

  factory SiteHeartbeat() => _instance;
  static SiteHeartbeat get instance => _instance;

  SiteHeartbeat._internal();

  void start() {
    if (_running) return;
    _running = true;
    _consecutiveFailures = 0;
    _scheduleNext(_heartbeatIntervalMs);
  }

  void stop() {
    _running = false;
    _clearTimer();
  }

  void resetFailures() {
    _consecutiveFailures = 0;
  }

  void _clearTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNext([int delayMs = _heartbeatIntervalMs]) {
    _clearTimer();
    if (!_running) return;
    _timer = Timer(Duration(milliseconds: delayMs), () {
      _runProbe();
    });
  }

  Future<void> _runProbe() async {
    if (!_running || _probing) return;
    final serverUrl = ServerConfigManager.instance.getCachedServerUrl();
    if (serverUrl.isEmpty) return;

    _probing = true;
    try {
      await FilmApi.getSiteConfig(force: true);
      _consecutiveFailures = 0;
    } catch (_) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= _maxFailures) {
        SourceGuard.intercept();
      }
    } finally {
      _probing = false;
      if (_running) {
        _scheduleNext(_heartbeatIntervalMs);
      }
    }
  }
}
