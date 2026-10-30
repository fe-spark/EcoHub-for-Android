import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/services/server_compat.dart';

void main() {
  group('ServerCompat Tests', () {
    test('default is V3 protocol with RESTful endpoints', () {
      final compat = ServerCompat.instance;
      expect(compat.endpoint(ApiEndpoint.home), '/home');
      expect(compat.endpoint(ApiEndpoint.dailyUpdates), '/daily-updates');
      expect(compat.endpoint(ApiEndpoint.categories), '/categories');
      expect(compat.endpoint(ApiEndpoint.categoryOverview), '/categories/overview');
      expect(compat.endpoint(ApiEndpoint.playInfo), '/films/play-info');
      expect(compat.endpoint(ApiEndpoint.related), '/films/related');
      expect(compat.endpoint(ApiEndpoint.search), '/films/search');
      expect(compat.endpoint(ApiEndpoint.filter), '/films/filter');
      expect(compat.endpoint(ApiEndpoint.hotKeywords), '/search/hot-keywords');
      expect(compat.endpoint(ApiEndpoint.statsView), '/stats/view');
      expect(compat.endpoint(ApiEndpoint.danmaku), '/film/danmaku');
    });

    test('updateFromProvideApp detects v2 server version and switches endpoints', () async {
      final compat = ServerCompat.instance;
      await compat.updateFromProvideApp({'version': 'v2.7.9'}, 'example.com');
      expect(compat.isV2, isTrue);
      expect(compat.isV3, isFalse);
      expect(compat.canCmsDirectSearch, isTrue);
      expect(compat.canLivePlay, isTrue);
      expect(compat.canDanmaku, isFalse);

      expect(compat.endpoint(ApiEndpoint.home), '/index');
      expect(compat.endpoint(ApiEndpoint.dailyUpdates), '/dailyUpdates');
      expect(compat.endpoint(ApiEndpoint.categories), '/navCategory');
      expect(compat.endpoint(ApiEndpoint.categoryOverview), '/filmClassify');
      expect(compat.endpoint(ApiEndpoint.playInfo), '/filmPlayInfo');
      expect(compat.endpoint(ApiEndpoint.related), '/filmRelate');
      expect(compat.endpoint(ApiEndpoint.search), '/searchFilm');
      expect(compat.endpoint(ApiEndpoint.filter), '/filmClassifySearch');
      expect(compat.endpoint(ApiEndpoint.hotKeywords), '/hotKeywords');
      expect(compat.endpoint(ApiEndpoint.statsView), '/stat/view');
      expect(compat.endpoint(ApiEndpoint.livePlayInfo), '/liveFilmPlayInfo');
      expect(compat.endpoint(ApiEndpoint.liveRelate), '/liveFilmRelate');
    });

    test('v2 resolves live play target when local mid is 0 or compound', () {
      final compat = ServerCompat.instance;
      // In v2 mode
      final target = compat.resolvePlayTarget(
        id: '0',
        sourceId: '1',
        sourceMid: '12345',
        title: '现场电影',
      );
      expect(target.route, '/play/live');
      expect(target.arguments['sourceId'], '1');
      expect(target.arguments['sourceMid'], '12345');
      expect(target.arguments['title'], '现场电影');

      final compoundTarget = compat.resolvePlayTarget(
        id: 'sourceA:555',
        title: '复合现场片',
      );
      expect(compoundTarget.route, '/play/live');
      expect(compoundTarget.arguments['sourceId'], 'sourceA');
      expect(compoundTarget.arguments['sourceMid'], '555');
    });

    test('updateFromProvideApp detects v3 server version and suppresses live play', () async {
      final compat = ServerCompat.instance;
      await compat.updateFromProvideApp({'version': 'v3.0.0-beta.20'}, 'example.com');
      expect(compat.isV3, isTrue);
      expect(compat.isV2, isFalse);
      expect(compat.canCmsDirectSearch, isFalse);
      expect(compat.canLivePlay, isFalse);
      expect(compat.canDanmaku, isTrue);

      expect(compat.endpoint(ApiEndpoint.home), '/home');
      expect(compat.endpoint(ApiEndpoint.playInfo), '/films/play-info');

      // In v3 mode, even compound or 0 mid redirects to standard play
      final target = compat.resolvePlayTarget(
        id: '100',
        sourceId: '1',
      );
      expect(target.route, '/play');
      expect(target.arguments['id'], '100');

      final zeroTarget = compat.resolvePlayTarget(
        id: '0',
        sourceId: '1',
        sourceMid: '12345',
      );
      expect(zeroTarget.route, '/play');
      expect(zeroTarget.arguments['id'], '0');
    });

    test('buildPlayInfoParams includes sid on v2 and strips sid on v3', () async {
      final compat = ServerCompat.instance;
      await compat.updateFromProvideApp({'version': 'v2.7.9'}, 'example.com');
      final paramsV2 = compat.buildPlayInfoParams(id: '12', playFrom: 'line1', sid: '99');
      expect(paramsV2['sid'], '99');

      await compat.updateFromProvideApp({'version': 'v3.0.0'}, 'example.com');
      final paramsV3 = compat.buildPlayInfoParams(id: '12', playFrom: 'line1', sid: '99');
      expect(paramsV3.containsKey('sid'), isFalse);
    });
  });
}
