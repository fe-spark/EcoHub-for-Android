import 'package:flutter/material.dart';
import 'server_config_manager.dart';

/// 软件源断连拦截与重连广播
class SourceGuard {
  static bool _intercepting = false;
  static int _skipCount = 0;
  static final List<VoidCallback> _listeners = [];
  static GlobalKey<NavigatorState>? navigatorKey;

  static void beginSkip() {
    _skipCount++;
  }

  static void endSkip() {
    if (_skipCount > 0) {
      _skipCount--;
    }
  }

  static void onReconnect(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  static void offReconnect(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void intercept([BuildContext? context]) {
    if (_skipCount > 0 || _intercepting) {
      return;
    }
    if (ServerConfigManager.instance.getCachedServerUrl().isEmpty) {
      return;
    }
    _intercepting = true;
    final nav = context != null ? Navigator.of(context) : navigatorKey?.currentState;
    if (nav != null) {
      nav.pushNamed('/server_config', arguments: {'mode': 'reconnect'}).then((_) {
        _intercepting = false;
      }).catchError((_) {
        _intercepting = false;
      });
    } else {
      _intercepting = false;
    }
  }

  static void markClosed() {
    _intercepting = false;
  }

  static void notifyReconnected() {
    _intercepting = false;
    final copy = List<VoidCallback>.from(_listeners);
    for (final l in copy) {
      l();
    }
  }
}
