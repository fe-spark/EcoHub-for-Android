import 'package:shared_preferences/shared_preferences.dart';

/// 协议版本
enum ServerProtocolVersion {
  v2,
  v3,
}

/// 业务端点枚举
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

/// 进播路由目标决策结果
class PlayRouteTarget {
  final String route;
  final Map<String, dynamic> arguments;

  const PlayRouteTarget({
    required this.route,
    required this.arguments,
  });
}

/// 兼容逻辑全量聚合器：集中管理 v2/v3 版本协商、路径映射、特性开关与参数适配
class ServerCompat {
  static final ServerCompat _instance = ServerCompat._internal();
  factory ServerCompat() => _instance;
  static ServerCompat get instance => _instance;
  ServerCompat._internal();

  ServerProtocolVersion _version = ServerProtocolVersion.v3;
  String _rawVersion = '';
  SharedPreferences? _pref;

  ServerProtocolVersion get protocolVersion => _version;
  bool get isV3 => _version == ServerProtocolVersion.v3;
  bool get isV2 => _version == ServerProtocolVersion.v2;
  String get rawVersion => _rawVersion;

  // 特性开关
  bool get canCmsDirectSearch => isV2; // 仅 v2 支持 CMS 直连搜索 Tab
  bool get canLivePlay => isV2;        // 仅 v2 支持未建档现场播放页
  bool get canDanmaku => isV3;         // 仅 v3 支持弹幕接口

  /// 初始化并根据 Host 作用域恢复历史协议版本
  void attachPreferences(SharedPreferences? pref, [String hostScope = '']) {
    _pref = pref;
    if (hostScope.isNotEmpty && _pref != null) {
      final cached = _pref!.getString('protocol_ver@$hostScope') ?? '';
      if (cached == 'v2') {
        _version = ServerProtocolVersion.v2;
      } else if (cached == 'v3') {
        _version = ServerProtocolVersion.v3;
      }
    }
  }

  /// 切换站点作用域时刷新当前协议版本
  void switchHostScope(String hostScope) {
    if (hostScope.isEmpty || _pref == null) return;
    final cached = _pref!.getString('protocol_ver@$hostScope') ?? '';
    if (cached == 'v2') {
      _version = ServerProtocolVersion.v2;
    } else if (cached == 'v3') {
      _version = ServerProtocolVersion.v3;
    }
  }

  /// 根据 /api/provide/app 或 /api/version 响应数据裁决协议版本并持久化
  Future<void> updateFromProvideApp(dynamic data, String hostScope) async {
    String ver = '';
    int protocol = 0;
    if (data is Map) {
      if (data['version'] != null) {
        ver = '${data['version']}'.trim().toLowerCase();
      }
      if (data['protocol'] is int) {
        protocol = data['protocol'];
      }
    }
    _rawVersion = ver;
    if (protocol >= 3 || ver.startsWith('v3.') || ver.startsWith('3.')) {
      _version = ServerProtocolVersion.v3;
    } else if (protocol == 2 || ver.startsWith('v2.') || ver.startsWith('2.')) {
      _version = ServerProtocolVersion.v2;
    } else {
      _version = ServerProtocolVersion.v3;
    }
    if (hostScope.isNotEmpty && _pref != null) {
      await _pref!.setString('protocol_ver@$hostScope', isV3 ? 'v3' : 'v2');
    }
  }

  /// 当 /api/provide/app 404 回退至 /api/health 时标记为 v2 协议
  Future<void> markFallbackV2(String hostScope) async {
    _version = ServerProtocolVersion.v2;
    _rawVersion = 'v2.x-legacy';
    if (hostScope.isNotEmpty && _pref != null) {
      await _pref!.setString('protocol_ver@$hostScope', 'v2');
    }
  }

  /// 集中端点解析
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
          return '';
        case ApiEndpoint.livePlayInfo:
          return '/liveFilmPlayInfo';
        case ApiEndpoint.liveRelate:
          return '/liveFilmRelate';
      }
    }
  }

  /// 归一化播放详情请求参数
  Map<String, dynamic> buildPlayInfoParams({
    required String id,
    String playFrom = '',
    int episode = 0,
    String sid = '',
  }) {
    final params = <String, dynamic>{
      'id': id,
      'playFrom': playFrom,
      'episode': episode,
    };
    if (isV2 && sid.isNotEmpty) {
      params['sid'] = sid;
    }
    return params;
  }

  /// 进播路由决策分流
  PlayRouteTarget resolvePlayTarget({
    required String id,
    String sourceId = '',
    String sourceMid = '',
    int? episodeIndex,
    double? currentTime,
    String title = '',
  }) {
    final cleanId = id.trim();
    final isLocalId = cleanId.isNotEmpty &&
        cleanId != '0' &&
        !cleanId.contains(':') &&
        int.tryParse(cleanId) != null;

    final args = <String, dynamic>{'id': cleanId};
    if (sourceId.isNotEmpty) args['sourceId'] = sourceId;
    if (episodeIndex != null && episodeIndex >= 0) {
      args['episodeIndex'] = '$episodeIndex';
    }
    if (currentTime != null && currentTime >= 0) {
      args['currentTime'] = '$currentTime';
    }
    if (title.isNotEmpty) args['title'] = title;

    // 在 v3 下或具备本地主站 mid 时，一律进入标准播放页
    if (isV3 || isLocalId) {
      return PlayRouteTarget(route: '/play', arguments: args);
    }

    // 仅在 v2 下且缺失本地 mid 时，分流进入现场播放页
    var liveSource = sourceId;
    var liveSid = sourceMid;
    if (cleanId.contains(':')) {
      final parts = cleanId.split(':');
      if (parts.length >= 2) {
        liveSource = parts[0];
        liveSid = parts[1];
      }
    }
    if (liveSource.isEmpty || liveSid.isEmpty) {
      return const PlayRouteTarget(route: '', arguments: {});
    }
    final liveArgs = <String, dynamic>{
      'sourceId': liveSource,
      'sourceMid': liveSid,
      if (title.isNotEmpty) 'title': title,
    };
    if (episodeIndex != null && episodeIndex >= 0) {
      liveArgs['episodeIndex'] = '$episodeIndex';
    }
    if (currentTime != null && currentTime >= 0) {
      liveArgs['currentTime'] = '$currentTime';
    }
    return PlayRouteTarget(route: '/play/live', arguments: liveArgs);
  }
}
