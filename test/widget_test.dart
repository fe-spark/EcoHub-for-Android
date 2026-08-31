import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/models/api_parser.dart';
import 'package:ecohub_android/utils/format_util.dart';
import 'package:ecohub_android/utils/server_config_manager.dart';
import 'package:ecohub_android/utils/app_version_util.dart';

void main() {
  group('ApiParser Tests', () {
    test('parseBasicConfig with full fields', () {
      final json = {
        'siteName': 'TestHub',
        'siteUrl': 'https://test.com',
        'state': true,
        'hint': 'hello',
        'tip': {
          'enabled': true,
          'title': '赞赏',
          'message': '谢谢支持',
          'channels': [
            {'key': 'wx', 'label': '微信', 'qrImage': '/wx.png', 'link': 'https://wx.com'}
          ]
        },
        'notice': {
          'enabled': true,
          'title': '公告',
          'content': '测试公告',
          'appVersion': '1.0.0',
        }
      };

      final config = ApiParser.parseBasicConfig(json);
      expect(config.siteName, 'TestHub');
      expect(config.tipEnabled, true);
      expect(config.tipChannels.length, 1);
      expect(config.tipChannels.first.label, '微信');
      expect(config.noticeEnabled, true);
      expect(config.noticeTitle, '公告');
      expect(config.noticeAppVersion, '1.0.0');
    });

    test('parseMovie and parseHome with fallback', () {
      final json = {
        'banners': [
          {'id': '101', 'mid': 101, 'name': 'Banner Movie', 'year': '2026'}
        ],
        'content': [
          {
            'nav': {'id': 1, 'name': '电影', 'show': true},
            'movies': [
              {'id': 1001, 'name': 'Movie 1', 'year': '2025', 'cName': '科幻'}
            ],
            'hot': []
          }
        ]
      };

      final home = ApiParser.parseHome(json);
      expect(home.banners.length, 1);
      expect(home.banners.first.name, 'Banner Movie');
      expect(home.content.length, 1);
      expect(home.content.first.nav.name, '电影');
      expect(home.content.first.movies.first.name, 'Movie 1');
    });
  });

  group('FormatUtil Tests', () {
    test('duration formatting', () {
      expect(FormatUtil.duration(0), '00:00');
      expect(FormatUtil.duration(65), '01:05');
      expect(FormatUtil.duration(3665), '01:01:05');
    });

    test('progress formatting', () {
      expect(FormatUtil.progress(0, 100), '未观看');
      expect(FormatUtil.progress(50, 100), '观看至 00:50 (50%)');
      expect(FormatUtil.progress(99, 100), '已看完');
    });

    test('joinMeta formatting', () {
      expect(FormatUtil.joinMeta(['2026', '电影', '中国']), '2026 · 电影 · 中国');
      expect(FormatUtil.joinMeta(['2026', '', '中国']), '2026 · 中国');
    });

    test('imageHeaders for bilibili and douban anti-hotlink', () {
      final biliHeaders = FormatUtil.imageHeaders('https://i0.hdslb.com/bfs/bangumi/image/19a2d01429bcba6b31791277c016e0d1aa465974.png');
      expect(biliHeaders['Referer'], 'https://www.bilibili.com/');
      expect(biliHeaders.containsKey('User-Agent'), true);

      final doubanHeaders = FormatUtil.imageHeaders('https://img9.doubanio.com/view/photo/s_ratio_poster/public/p480747492.jpg');
      expect(doubanHeaders['Referer'], 'https://movie.douban.com/');

      final genericHeaders = FormatUtil.imageHeaders('https://example.com/cover.jpg');
      expect(genericHeaders.containsKey('Referer'), false);
      expect(genericHeaders.containsKey('User-Agent'), true);
    });
  });

  group('ServerConfigManager Tests', () {
    test('normalizeRaw and stripApiSuffix', () {
      final manager = ServerConfigManager.instance;
      expect(manager.normalizeRaw('eco.fe-spark.cn'), 'https://eco.fe-spark.cn');
      expect(manager.normalizeRaw('http://eco.fe-spark.cn/'), 'http://eco.fe-spark.cn');
      expect(ServerConfigManager.stripApiSuffix('https://eco.fe-spark.cn/api'), 'https://eco.fe-spark.cn');
      expect(ServerConfigManager.stripApiSuffix('https://eco.fe-spark.cn/api/'), 'https://eco.fe-spark.cn');
      expect(ServerConfigManager.hostScope('https://eco.fe-spark.cn/api'), 'eco.fe-spark.cn');
    });
  });

  group('AppVersionUtil Tests', () {
    test('version comparison', () {
      expect(AppVersionUtil.compareVersion('1.0.1', '1.0.0'), 1);
      expect(AppVersionUtil.compareVersion('1.0.0', '1.0.0'), 0);
      expect(AppVersionUtil.compareVersion('1.0.0', '1.0.1'), -1);
      expect(AppVersionUtil.isNewerVersion('1.2.0', '1.1.9'), true);
    });

    test('version match filter', () {
      expect(AppVersionUtil.isVersionMatched('1.0.0', '*'), true);
      expect(AppVersionUtil.isVersionMatched('1.0.0', 'all'), true);
      expect(AppVersionUtil.isVersionMatched('1.0.0', '1.0.0, 1.0.1'), true);
      expect(AppVersionUtil.isVersionMatched('1.0.2', '1.0.0, 1.0.1'), false);
    });
  });
}
