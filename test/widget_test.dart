import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/models/api_parser.dart';
import 'package:ecohub_android/utils/format_util.dart';
import 'package:ecohub_android/utils/server_config_manager.dart';
import 'package:ecohub_android/utils/app_version_util.dart';
import 'package:ecohub_android/utils/clipboard_sniffer.dart';
import 'package:ecohub_android/utils/nav_util.dart';
import 'package:ecohub_android/utils/breakpoint.dart';
import 'package:ecohub_android/common/app_theme.dart';
import 'package:ecohub_android/components/filter_tag_row.dart';
import 'package:ecohub_android/components/filter_bar.dart';
import 'package:ecohub_android/components/dynamic_sliver_appbar.dart';
import 'package:ecohub_android/components/sticky_appbar.dart';

void _mockClipboard(WidgetTester tester, String text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.getData') {
        if (text.isEmpty) return null;
        return <String, dynamic>{'text': text};
      }
      return null;
    },
  );
}

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

    test('parseFilter keeps all tag rows even if sortList only has Sort', () {
      final result = ApiParser.parseFilter({
        'title': {'name': '剧集', 'id': 1},
        'list': [],
        'page': {'current': 1, 'pageCount': 1, 'total': 10, 'pageSize': 21},
        'params': {'Sort': 'update_stamp'},
        'search': {
          'titles': {'Category': '类型', 'Plot': '剧情', 'Sort': '排序'},
          'sortList': ['Sort'],
          'tags': {
            'Category': [
              {'Name': '全部', 'Value': ''},
              {'Name': '韩剧', 'Value': '2'},
            ],
            'Plot': [
              {'name': '全部', 'value': ''},
              {'name': '爱情', 'value': '爱情'},
            ],
            'Sort': [
              {'Name': '最近更新', 'Value': 'update_stamp'},
              {'Name': '人气', 'Value': 'hits'},
            ],
          },
        },
      });
      expect(result.search.sortList, ['Sort']);
      expect(result.search.tagKeys.toSet(), {'Category', 'Plot', 'Sort'});
      expect(result.search.tagNames[result.search.tagKeys.indexOf('Category')], ['全部', '韩剧']);
      expect(result.search.tagNames[result.search.tagKeys.indexOf('Plot')], ['全部', '爱情']);
    });

    test('parsePlay falls back from detail root when descriptor empty', () {
      final info = ApiParser.parsePlay({
        'detail': {
          'id': 1,
          'name': 'Film',
          'descriptor': {},
          'subTitle': 'ST',
          'typeName': '剧情',
          'actor': 'A',
          'director': 'D',
          'blurb': '简介',
          'year': '2024',
          'list': [],
        },
        'current': {'episode': '1', 'link': 'http://x'},
        'currentPlayFrom': 's1',
        'currentEpisode': 0,
      });
      expect(info.detail.descriptor.subTitle, 'ST');
      expect(info.detail.descriptor.cName, '剧情');
      expect(info.detail.descriptor.actor, 'A');
      expect(info.detail.descriptor.director, 'D');
      expect(info.detail.descriptor.blurb, '简介');
      expect(info.detail.descriptor.content, '简介');
      expect(info.detail.descriptor.year, '2024');
    });

    test('parsePlay score from detail.vod_score', () {
      final info = ApiParser.parsePlay({
        'detail': {
          'id': 2,
          'name': 'Film2',
          'descriptor': {},
          'vod_score': '8.5',
          'list': [],
        },
        'current': {},
      });
      expect(info.detail.descriptor.dbScore, '8.5');
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
      expect(AppVersionUtil.compareVersion('1.1.5', '1.1.5-beta'), 1);
      expect(AppVersionUtil.compareVersion('1.1.5-beta', '1.1.5'), -1);
      expect(AppVersionUtil.compareVersion('1.1.5-beta.2', '1.1.5-beta.1'), 1);
    });

    test('version match filter', () {
      expect(AppVersionUtil.isVersionMatched('1.0.0', '*'), true);
      expect(AppVersionUtil.isVersionMatched('1.0.0', 'all'), true);
      expect(AppVersionUtil.isVersionMatched('1.0.0', '1.0.0, 1.0.1'), true);
      expect(AppVersionUtil.isVersionMatched('1.0.2', '1.0.0, 1.0.1'), false);
      expect(AppVersionUtil.isVersionMatched('1.0.0', 'v1.0.0'), true);
      expect(AppVersionUtil.isVersionMatched('v1.0.0', '1.0.0'), true);
    });
  });

  group('ClipboardSniffer Tests', () {
    setUp(ClipboardSniffer.reset);
    tearDown(ClipboardSniffer.reset);

    test('extractVideoUrl empty and non-http', () {
      expect(ClipboardSniffer.extractVideoUrl(''), '');
      expect(ClipboardSniffer.extractVideoUrl('   '), '');
      expect(ClipboardSniffer.extractVideoUrl('没有链接'), '');
      expect(ClipboardSniffer.extractVideoUrl('ftp://x.com/a.mp4'), '');
    });

    test('extractVideoUrl from mixed text and trailing punct', () {
      expect(
        ClipboardSniffer.extractVideoUrl('看这个 https://cdn.example.com/a.m3u8 真好看'),
        'https://cdn.example.com/a.m3u8',
      );
      expect(
        ClipboardSniffer.extractVideoUrl('http://host/v.mp4。'),
        'http://host/v.mp4',
      );
      expect(
        ClipboardSniffer.extractVideoUrl('https://host/v.m3u8)'),
        'https://host/v.m3u8',
      );
      expect(
        ClipboardSniffer.extractVideoUrl('地址："https://host/v.mp4"'),
        'https://host/v.mp4',
      );
    });

    test('extractVideoUrl stops at CJK and takes first url', () {
      expect(
        ClipboardSniffer.extractVideoUrl('https://a.com/x中文.mp4'),
        'https://a.com/x',
      );
      expect(
        ClipboardSniffer.extractVideoUrl('https://a.com/1.mp4 https://b.com/2.m3u8'),
        'https://a.com/1.mp4',
      );
    });

    testWidgets('sniff reads clipboard once and skips handled raw', (tester) async {
      const raw = '看这个 https://cdn.example.com/a.m3u8';
      _mockClipboard(tester, raw);

      final first = await ClipboardSniffer.sniff();
      expect(first.url, 'https://cdn.example.com/a.m3u8');
      expect(first.raw, raw);

      ClipboardSniffer.markHandled(first.raw);
      final second = await ClipboardSniffer.sniff();
      expect(second.url, '');
      expect(second.raw, raw);

      ClipboardSniffer.reset();
      final third = await ClipboardSniffer.sniff();
      expect(third.url, 'https://cdn.example.com/a.m3u8');
    });

    testWidgets('sniff empty clipboard', (tester) async {
      _mockClipboard(tester, '');
      final res = await ClipboardSniffer.sniff();
      expect(res.url, '');
      expect(res.raw, '');
    });
  });

  group('NavUtil Tests', () {
    test('param reads string and fallback', () {
      expect(NavUtil.param({'url': 'https://a.com/v.mp4'}, 'url'), 'https://a.com/v.mp4');
      expect(NavUtil.param({'url': 1}, 'url'), '1');
      expect(NavUtil.param({}, 'url', 'x'), 'x');
      expect(NavUtil.param(null, 'url', 'x'), 'x');
    });
  });

  group('Breakpoint Tests', () {
    test('cardWidthOf matches OHOS formula', () {
      expect(Breakpoint.cardWidthOf(360), 104);
      expect(Breakpoint.cardWidthOf(390), 114);
      expect(Breakpoint.cardWidthOf(600), 136);
    });
  });

  group('FilterTagRow', () {
    testWidgets('highlights selected chip with accent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterTagRow(
              filterKey: 'Sort',
              title: '排序',
              names: const ['最新', '最热'],
              values: const ['update_stamp', 'hits'],
              selected: 'update_stamp',
              onPick: (k, v) {},
            ),
          ),
        ),
      );
      expect(find.text('排序'), findsOneWidget);
      expect(find.text('最新'), findsOneWidget);
      final latest = tester.widget<Text>(find.text('最新'));
      expect(latest.style?.color, AppTheme.textPrimary);
      final hot = tester.widget<Text>(find.text('最热'));
      expect(hot.style?.color, AppTheme.textSecondary);
    });

    testWidgets('sliver filter chrome lays out', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const DynamicSliverAppBar(
                  maxHeight: 88,
                  child: SizedBox(height: 88, child: ColoredBox(color: Colors.black)),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyAppbar(child: const SizedBox(height: 48)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DynamicSliverAppBar), findsOneWidget);
    });

    testWidgets('FilterBar parent stretches to all rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                DynamicSliverAppBar(
                  maxHeight: 800,
                  child: FilterBar(
                    keys: const ['Sort', 'Category', 'Plot'],
                    titleOf: (k) => k,
                    namesOf: (k) => const ['全部'],
                    valuesOf: (k) => const [''],
                    selectedOf: (k) => '',
                    onPick: (a, b) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FilterTagRow), findsNWidgets(3));
      expect(
        tester.getSize(find.byType(FilterBar)).height,
        44 * 3 + AppTheme.spaceSm * 2,
      );
    });
  });
}
