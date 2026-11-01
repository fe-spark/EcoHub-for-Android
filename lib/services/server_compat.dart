import 'package:shared_preferences/shared_preferences.dart';

enum ServerProtocolVersion {
  v2(2),
  v3(3);

  final int value;
  const ServerProtocolVersion(this.value);
}

enum ApiEndpoint {
  home,
  dailyUpdates,
  categories,
  categoryOverview,
  playInfo,
  related,
  search,
  filter,
  hotKeywords,
  statsView,
  danmaku,
  livePlayInfo,
  liveRelate,
}

/// 服务端协议版本与端点适配器，全量对齐鸿蒙端 `ServerCompat.ets`
class ServerCompat {
  static final ServerCompat instance = ServerCompat._();
  ServerCompat._();

  ServerProtocolVersion _version = ServerProtocolVersion.v3;
  String _rawVersionStr = '';

  ServerProtocolVersion get protocolVersion => _version;
  bool get isV3 => _version == ServerProtocolVersion.v3;
  bool get isV2 => _version == ServerProtocolVersion.v2;
  String get rawVersion => _rawVersionStr;

  bool get canCmsDirectSearch => isV2;
  bool get canLivePlay => isV2;
  bool get canDanmaku => isV3;

  Future<void> attachPreferences(String hostScope) async {
    if (hostScope.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('protocol_ver@$hostScope') ?? '';
      if (cached == 'v2') {
        _version = ServerProtocolVersion.v2;
      } else if (cached == 'v3') {
        _version = ServerProtocolVersion.v3;
      }
    } catch (_) {}
  }

  Future<void> switchHostScope(String hostScope) async {
    await attachPreferences(hostScope);
  }

  Future<void> updateFromProvideApp(dynamic data, String hostScope) async {
    var ver = '';
    var protocol = 0;
    if (data is Map) {
      if (data['version'] != null) {
        ver = '${data['version']}'.trim().toLowerCase();
      }
      if (data['protocol'] is num) {
        protocol = (data['protocol'] as num).toInt();
      }
    }
    _rawVersionStr = ver;
    if (protocol >= 3 || ver.startsWith('v3.') || ver.startsWith('3.')) {
      _version = ServerProtocolVersion.v3;
    } else if (protocol == 2 || ver.startsWith('v2.') || ver.startsWith('2.')) {
      _version = ServerProtocolVersion.v2;
    } else {
      _version = ServerProtocolVersion.v3;
    }

    if (hostScope.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('protocol_ver@$hostScope', isV3 ? 'v3' : 'v2');
      } catch (_) {}
    }
  }

  Future<void> markFallbackV2(String hostScope) async {
    _version = ServerProtocolVersion.v2;
    _rawVersionStr = 'v2.x-legacy';
    if (hostScope.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('protocol_ver@$hostScope', 'v2');
      } catch (_) {}
    }
  }

  String endpoint(ApiEndpoint ep) {
    if (isV3) {
      switch (ep) {
        case ApiEndpoint.home:
          return '/home';
        case ApiEndpoint.dailyUpdates:
          return '/daily-updates';
        case ApiEndpoint.categories:
          return '/categories';
        case ApiEndpoint.categoryOverview:
          return '/categories/overview';
        case ApiEndpoint.playInfo:
          return '/films/play-info';
        case ApiEndpoint.related:
          return '/films/related';
        case ApiEndpoint.search:
          return '/films/search';
        case ApiEndpoint.filter:
          return '/films/filter';
        case ApiEndpoint.hotKeywords:
          return '/search/hot-keywords';
        case ApiEndpoint.statsView:
          return '/stats/view';
        case ApiEndpoint.danmaku:
          return '/film/danmaku';
        case ApiEndpoint.livePlayInfo:
          return '/films/play-info';
        case ApiEndpoint.liveRelate:
          return '/films/related';
      }
    } else {
      switch (ep) {
        case ApiEndpoint.home:
          return '/index';
        case ApiEndpoint.dailyUpdates:
          return '/dailyUpdates';
        case ApiEndpoint.categories:
          return '/navCategory';
        case ApiEndpoint.categoryOverview:
          return '/filmClassify';
        case ApiEndpoint.playInfo:
          return '/filmPlayInfo';
        case ApiEndpoint.related:
          return '/filmRelate';
        case ApiEndpoint.search:
          return '/searchFilm';
        case ApiEndpoint.filter:
          return '/filmClassifySearch';
        case ApiEndpoint.hotKeywords:
          return '/hotKeywords';
        case ApiEndpoint.statsView:
          return '/stat/view';
        case ApiEndpoint.danmaku:
          return '/film/danmaku';
        case ApiEndpoint.livePlayInfo:
          return '/liveFilmPlayInfo';
        case ApiEndpoint.liveRelate:
          return '/liveFilmRelate';
      }
    }
  }
}
