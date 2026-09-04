import 'package:flutter/material.dart';
import '../api/http_client.dart';

const _skipRoutes = {
  '/',
  '/play',
  '/search',
  '/filter',
  '/server_config',
};

const _screenNames = {
  '/main': 'MainScaffold',
  '/history': 'HistoryPage',
  '/tip': 'TipPage',
  '/custom_player': 'CustomPlayerPage',
};

class EcoHubRouteObserver extends NavigatorObserver {
  void _report(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty || _skipRoutes.contains(name)) {
      return;
    }
    final page = _screenNames[name] ?? name;
    HttpClient.instance.trackView('browse', '', page);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _report(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _report(newRoute);
    }
  }
}
