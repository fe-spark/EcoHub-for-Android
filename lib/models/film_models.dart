/// 赞赏渠道信息
class TipChannel {
  final String key;
  final String label;
  final String qrImage;
  final String link;

  TipChannel({
    required this.key,
    required this.label,
    required this.qrImage,
    required this.link,
  });
}

/// 站点基础配置
class BasicConfig {
  final String siteName;
  final String siteUrl;
  final String logo;
  final String keyword;
  final String describe;
  final bool state;
  final String hint;
  final bool tipEnabled;
  final String tipTitle;
  final String tipMessage;
  final List<TipChannel> tipChannels;
  final bool noticeEnabled;
  final String noticeTitle;
  final String noticeContent;
  final bool noticeShowInWeb;
  final bool noticeShowInApp;
  final String noticeAppVersion;
  final String noticeVersion;

  BasicConfig({
    this.siteName = 'EcoHub',
    this.siteUrl = '',
    this.logo = '',
    this.keyword = '',
    this.describe = '',
    this.state = true,
    this.hint = '',
    this.tipEnabled = false,
    this.tipTitle = '赞赏支持',
    this.tipMessage = '',
    this.tipChannels = const [],
    this.noticeEnabled = false,
    this.noticeTitle = '站点公告',
    this.noticeContent = '',
    this.noticeShowInWeb = true,
    this.noticeShowInApp = true,
    this.noticeAppVersion = '',
    this.noticeVersion = '',
  });
}

/// 影片分类条目
class CategoryItem {
  final int id;
  final int pid;
  final String name;
  final bool show;
  final List<CategoryItem> children;

  CategoryItem({
    required this.id,
    required this.pid,
    required this.name,
    this.show = true,
    this.children = const [],
  });
}

/// 影片基础卡片信息
class MovieBasicInfo {
  final int id;
  final int cid;
  final int pid;
  final String name;
  final String subTitle;
  final String cName;
  final String state;
  final String picture;
  final String pictureSlide;
  final String poster;
  final String actor;
  final String director;
  final String blurb;
  final String remarks;
  final String area;
  final String year;
  final String language;
  final String classTag;
  final String mid;
  final String sourceId;
  final int sourceMid;

  MovieBasicInfo({
    required this.id,
    this.cid = 0,
    this.pid = 0,
    required this.name,
    this.subTitle = '',
    this.cName = '',
    this.state = '',
    this.picture = '',
    this.pictureSlide = '',
    this.poster = '',
    this.actor = '',
    this.director = '',
    this.blurb = '',
    this.remarks = '',
    this.area = '',
    this.year = '',
    this.language = '',
    this.classTag = '',
    this.mid = '',
    this.sourceId = '',
    this.sourceMid = 0,
  });
}

class SearchSourceTab {
  final String id;
  final String name;
  final int count;
  final bool loading;

  SearchSourceTab({
    required this.id,
    required this.name,
    this.count = 0,
    this.loading = false,
  });
}

/// 首页轮播海报条目
class BannerItem {
  final String id;
  final int mid;
  final String name;
  final String year;
  final String cName;
  final String poster;
  final String picture;
  final String pictureSlide;
  final String remark;
  final String blurb;
  final String area;

  BannerItem({
    required this.id,
    required this.mid,
    required this.name,
    this.year = '',
    this.cName = '',
    this.poster = '',
    this.picture = '',
    this.pictureSlide = '',
    this.remark = '',
    this.blurb = '',
    this.area = '',
  });
}

/// 首页分类区块数据
class HomeSection {
  final CategoryItem nav;
  final List<MovieBasicInfo> movies;
  final List<MovieBasicInfo> hot;

  HomeSection({
    required this.nav,
    required this.movies,
    required this.hot,
  });
}

/// 首页全量数据
class HomeData {
  final List<BannerItem> banners;
  final List<HomeSection> content;

  HomeData({
    required this.banners,
    required this.content,
  });
}

/// 分页基础元数据
class PageInfo {
  final int pageSize;
  final int current;
  final int pageCount;
  final int total;

  PageInfo({
    this.pageSize = 20,
    this.current = 1,
    this.pageCount = 1,
    this.total = 0,
  });
}

/// 每日更新分类
class DailyUpdateCategory {
  final int pid;
  final String name;
  final int count;

  DailyUpdateCategory({
    required this.pid,
    required this.name,
    required this.count,
  });
}

/// 每日更新返回结果
class DailyUpdateResult {
  final List<MovieBasicInfo> list;
  final PageInfo page;
  final List<DailyUpdateCategory> categories;

  DailyUpdateResult({
    required this.list,
    required this.page,
    required this.categories,
  });
}

/// 筛选搜索元数据
class FilterSearchMeta {
  final List<String> titles;
  final List<String> titleKeys;
  final List<String> sortList;
  final List<String> tagKeys;
  final List<List<String>> tagNames;
  final List<List<String>> tagValues;

  FilterSearchMeta({
    this.titles = const [],
    this.titleKeys = const [],
    this.sortList = const [],
    this.tagKeys = const [],
    this.tagNames = const [],
    this.tagValues = const [],
  });
}

/// 筛选结果
class FilterResult {
  final String titleName;
  final int titleId;
  final List<MovieBasicInfo> list;
  final PageInfo page;
  final List<String> params;
  final List<String> paramKeys;
  final FilterSearchMeta search;

  FilterResult({
    required this.titleName,
    required this.titleId,
    required this.list,
    required this.page,
    this.params = const [],
    this.paramKeys = const [],
    required this.search,
  });
}

/// 影片单集播放地址
class MovieUrlInfo {
  final String episode;
  final String link;

  MovieUrlInfo({
    required this.episode,
    required this.link,
  });

  Map<String, dynamic> toJson() => {
    'episode': episode,
    'link': link,
  };
}

/// 播放源
class PlaySource {
  final String id;
  final String sourceId;
  final String name;
  final List<MovieUrlInfo> linkList;

  PlaySource({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.linkList,
  });
}

/// 影片详情描述符
class MovieDescriptor {
  final String subTitle;
  final String cName;
  final String enName;
  final String classTag;
  final String actor;
  final String director;
  final String writer;
  final String blurb;
  final String remarks;
  final String releaseDate;
  final String area;
  final String language;
  final String year;
  final String state;
  final String updateTime;
  final String dbScore;
  final String content;

  MovieDescriptor({
    this.subTitle = '',
    this.cName = '',
    this.enName = '',
    this.classTag = '',
    this.actor = '',
    this.director = '',
    this.writer = '',
    this.blurb = '',
    this.remarks = '',
    this.releaseDate = '',
    this.area = '',
    this.language = '',
    this.year = '',
    this.state = '',
    this.updateTime = '',
    this.dbScore = '',
    this.content = '',
  });
}

/// 影片详情全量信息
class MovieDetail {
  final int id;
  final int cid;
  final int pid;
  final String name;
  final String picture;
  final String pictureSlide;
  final MovieDescriptor descriptor;
  final List<PlaySource> list;
  final int localUpdateTime;
  final int rawCid;

  MovieDetail({
    required this.id,
    this.cid = 0,
    this.pid = 0,
    required this.name,
    this.picture = '',
    this.pictureSlide = '',
    required this.descriptor,
    this.list = const [],
    this.localUpdateTime = 0,
    this.rawCid = 0,
  });
}

/// 播放初始化信息
class PlayInfo {
  final MovieDetail detail;
  final MovieUrlInfo current;
  final String currentPlayFrom;
  final int currentEpisode;

  PlayInfo({
    required this.detail,
    required this.current,
    required this.currentPlayFrom,
    required this.currentEpisode,
  });
}
/// 弹幕评论条目，对齐 OHOS `DanmakuComment`
///
/// 服务端 `GET /film/danmaku` 返回归一化 JSON：
/// `{text, time, color: "#rrggbb", mode: 0|1|2, border: bool}`。
/// 解析时兼容数字/字符串混用、B 站原始 mode（4=底部、5=顶部）与十进制整数颜色。
class DanmakuComment {
  final String text;
  final double time; // 触发时间（秒）
  final String color; // #RRGGBB
  final int mode; // 0: 滚动弹幕(R2L), 1: 顶部固定, 2: 底部固定
  final bool border; // 高亮（带边框），对应服务端 DanmakuItem.border

  const DanmakuComment({
    required this.text,
    required this.time,
    this.color = '#FFFFFF',
    this.mode = 0,
    this.border = false,
  });

  /// 宽松解析单条弹幕；text 为空或 time 非法时返回 null
  static DanmakuComment? tryParse(Map<dynamic, dynamic> json) {
    final text = (json['text'] ?? '').toString().trim();
    if (text.isEmpty) return null;
    final time = _toDouble(json['time']);
    if (time == null || !time.isFinite || time < 0) return null;
    return DanmakuComment(
      text: text,
      time: time,
      color: normalizeColor(json['color']),
      mode: normalizeMode(json['mode']),
      border: _toBool(json['border']) || _toBool(json['highlight']),
    );
  }

  factory DanmakuComment.fromJson(Map<String, dynamic> json) {
    return tryParse(json) ??
        DanmakuComment(text: (json['text'] ?? '').toString(), time: _toDouble(json['time']) ?? 0.0);
  }

  /// 0/1/2 为服务端归一化取值；4/5 为 B 站 / 弹弹play 原始取值（4 底部、5 顶部）
  static int normalizeMode(dynamic raw) {
    final v = raw is num ? raw.toInt() : (int.tryParse('${raw ?? ''}'.trim()) ?? 0);
    switch (v) {
      case 1:
      case 5:
        return 1;
      case 2:
      case 4:
        return 2;
      default:
        return 0;
    }
  }

  /// 统一成 `#RRGGBB`：支持 `#rgb`、`#rrggbb`、`#aarrggbb`、`0xrrggbb` 与十进制整数（如 16777215）
  static String normalizeColor(dynamic raw) {
    if (raw is num) return _fromInt(raw.toInt());
    var s = '${raw ?? ''}'.trim();
    if (s.isEmpty) return '#FFFFFF';
    if (s.startsWith('#')) {
      s = s.substring(1);
    } else if (s.toLowerCase().startsWith('0x')) {
      s = s.substring(2);
    } else if (RegExp(r'^\d+$').hasMatch(s) && s.length != 6) {
      // 无前缀的纯数字且不是 6 位：按 B 站 / 弹弹play 十进制颜色处理
      return _fromInt(int.tryParse(s) ?? 0xFFFFFF);
    }
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) return '#FFFFFF';
    if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
    if (s.length == 8) s = s.substring(2); // AARRGGBB
    if (s.length != 6) return '#FFFFFF';
    return '#${s.toUpperCase()}';
  }

  static String _fromInt(int v) {
    if (v < 0 || v > 0xFFFFFF) return '#FFFFFF';
    return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v == null) return null;
    return double.tryParse(v.toString().trim());
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = '${v ?? ''}'.trim().toLowerCase();
    return s == 'true' || s == '1';
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'time': time,
    'color': color,
    'mode': mode,
    'border': border,
  };
}

/// 观看历史记录项
class HistoryItem {
  final String id;
  final String name;
  final String picture;
  final String sourceId;
  final String sourceName;
  final int episodeIndex;
  final String episode;
  final double currentTime;
  final double duration;
  final int timeStamp;

  HistoryItem({
    required this.id,
    required this.name,
    this.picture = '',
    this.sourceId = '',
    this.sourceName = '',
    this.episodeIndex = 0,
    this.episode = '',
    this.currentTime = 0,
    this.duration = 0,
    required this.timeStamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'picture': picture,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'episodeIndex': episodeIndex,
    'episode': episode,
    'currentTime': currentTime,
    'duration': duration,
    'timeStamp': timeStamp,
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      picture: '${json['picture'] ?? ''}',
      sourceId: '${json['sourceId'] ?? ''}',
      sourceName: '${json['sourceName'] ?? ''}',
      episodeIndex: (json['episodeIndex'] as num?)?.toInt() ?? 0,
      episode: '${json['episode'] ?? ''}',
      currentTime: (json['currentTime'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
      timeStamp: (json['timeStamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// 收藏条目，对齐 OHOS `FavoriteItem`
class FavoriteItem {
  final String id;
  final String name;
  final String picture;
  final String cName;
  final String remarks;
  final String year;
  final String area;
  final String subTitle;
  final String actor;
  final String director;
  final int createdAt;

  FavoriteItem({
    required this.id,
    required this.name,
    this.picture = '',
    this.cName = '',
    this.remarks = '',
    this.year = '',
    this.area = '',
    this.subTitle = '',
    this.actor = '',
    this.director = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'picture': picture,
    'cName': cName,
    'remarks': remarks,
    'year': year,
    'area': area,
    'subTitle': subTitle,
    'actor': actor,
    'director': director,
    'createdAt': createdAt,
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      picture: '${json['picture'] ?? ''}',
      cName: '${json['cName'] ?? ''}',
      remarks: '${json['remarks'] ?? ''}',
      year: '${json['year'] ?? ''}',
      area: '${json['area'] ?? ''}',
      subTitle: '${json['subTitle'] ?? ''}',
      actor: '${json['actor'] ?? ''}',
      director: '${json['director'] ?? ''}',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// 搜索返回结果
class SearchResult {
  final List<MovieBasicInfo> list;
  final PageInfo page;
  final List<SearchSourceTab> sources;
  final String error;

  SearchResult({
    required this.list,
    required this.page,
    this.sources = const [],
    this.error = '',
  });
}
