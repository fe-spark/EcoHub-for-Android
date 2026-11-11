import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/components/player/danmaku_status.dart';
import 'package:ecohub_android/components/player/player_bars.dart';
import 'package:ecohub_android/models/film_models.dart';

Widget _bar(double width, DanmakuStatus? status, {bool isFull = true}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: width,
          child: PlayerBottomBar(
            isReady: true,
            isOpening: false,
            showHud: true,
            errorText: '',
            cinemaHud: false,
            isFull: isFull,
            isPlaying: true,
            muted: false,
            currentPosition: const Duration(seconds: 10),
            totalDuration: const Duration(seconds: 100),
            currentSpeed: 1.0,
            scaleLabel: '适应',
            canDanmaku: true,
            danmakuStatus: status,
            onTogglePlay: () {},
            onToggleFull: () {},
            onToggleMute: () {},
            onSpeed: () {},
            onSeekTo: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DanmakuStatus 文案与网页端一致', () {
    test('加载中', () {
      expect(DanmakuStatus.loading.placeholder, '弹幕加载中…');
      expect(DanmakuStatus.loading.tone, DanmakuStatusTone.loading);
    });

    test('正常', () {
      final s = DanmakuStatus.loaded(120, const DanmakuMeta(local: 20, network: 100, networkStatus: 'ok'));
      expect(s.placeholder, '共 120 条弹幕，说点什么吧');
      expect(s.title, '已加载 120 条弹幕（全网 100 条）');
      expect(s.tone, DanmakuStatusTone.ok);
    });

    test('没有全网弹幕', () {
      final s = DanmakuStatus.loaded(3, const DanmakuMeta(local: 3, networkStatus: 'empty', networkReason: '未匹配到剧集'));
      expect(s.placeholder, '共 3 条弹幕，未找到全网弹幕');
      expect(s.title, '已加载 3 条弹幕，未找到全网弹幕：未匹配到剧集');
      expect(s.tone, DanmakuStatusTone.warn);
      expect(DanmakuStatus.loaded(0, const DanmakuMeta(networkStatus: 'empty')).placeholder, '未找到全网弹幕，说点什么吧');
    });

    test('全网失败时注明已加载本站条数', () {
      final s = DanmakuStatus.loaded(12, const DanmakuMeta(local: 12, networkStatus: 'error', networkReason: '请求超时'));
      expect(s.placeholder, '全网弹幕加载失败：请求超时');
      expect(s.title, '全网弹幕加载失败：请求超时（已加载本站 12 条）');
      expect(s.tone, DanmakuStatusTone.error);
      expect(DanmakuStatus.loaded(0, const DanmakuMeta(networkStatus: 'error')).title, '全网弹幕加载失败：未知原因');
    });

    test('接口失败', () {
      expect(DanmakuStatus.requestFailed('HTTP 502').placeholder, '弹幕加载失败：HTTP 502');
      expect(DanmakuStatus.requestFailed().placeholder, '弹幕加载失败：未知原因');
    });

    test('未开全网弹幕只报本站条数、不显示状态点', () {
      final s = DanmakuStatus.loaded(0, null);
      expect(s.placeholder, '发个友善的弹幕见证当下');
      expect(s.title, '');
      expect(s.tone, DanmakuStatusTone.none);
    });

    test('解析接口 meta', () {
      final m = DanmakuMeta.fromJson({'local': 2, 'network': 5, 'networkStatus': 'ok'})!;
      expect([m.local, m.network, m.networkStatus], [2, 5, 'ok']);
      expect(DanmakuMeta.fromJson(null), isNull);
      final s = DanmakuMeta.fromJson({'local': '3', 'network': '12', 'networkStatus': 'ok'})!;
      expect([s.local, s.network], [3, 12]);
      final bad = DanmakuMeta.fromJson({'local': 'abc', 'network': null})!;
      expect([bad.local, bad.network], [0, 0]);
    });
  });

  testWidgets('宽控制条显示状态文字和状态点，弹幕开关上不再画点', (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final status = DanmakuStatus.loaded(12, const DanmakuMeta(networkStatus: 'error', networkReason: '请求超时'));
    await tester.pumpWidget(_bar(800, status));
    expect(find.text('全网弹幕加载失败：请求超时'), findsOneWidget);
    expect(find.byKey(const ValueKey('danmaku-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('danmaku-status-dot')), findsNothing);
  });

  testWidgets('窄控制条收起文字，只在弹幕开关上显示状态点', (tester) async {
    tester.view.physicalSize = const Size(480, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_bar(480, DanmakuStatus.loaded(5, const DanmakuMeta(networkStatus: 'empty')), isFull: false));
    expect(find.text('共 5 条弹幕，未找到全网弹幕'), findsNothing);
    expect(find.byKey(const ValueKey('danmaku-status-dot')), findsOneWidget);
  });

  testWidgets('未开全网弹幕时窄控制条不画点', (tester) async {
    tester.view.physicalSize = const Size(480, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_bar(480, DanmakuStatus.loaded(5, null), isFull: false));
    expect(find.byKey(const ValueKey('danmaku-status-dot')), findsNothing);
  });
}
