import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/components/player/player_danmaku_layer.dart';
import 'package:ecohub_android/models/film_models.dart';

Widget _host(Widget child, {Size size = const Size(844, 390)}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: size.width, height: size.height, child: child)),
    ),
  );
}

void main() {
  testWidgets('dense second shows many scroll danmaku plus top/bottom fixed, colors and highlight', (tester) async {
    final comments = <DanmakuComment>[];
    // 1 秒内 120 条滚动弹幕（密集时段），外加顶部/底部固定、彩色与高亮弹幕
    for (var i = 0; i < 120; i++) {
      comments.add(DanmakuComment(text: '密集弹幕测试$i', time: 1.0 + i / 120.0));
    }
    for (var i = 0; i < 3; i++) {
      comments.add(DanmakuComment(text: '顶部$i', time: 1.2, mode: 1, color: '#FF0000'));
      comments.add(DanmakuComment(text: '底部$i', time: 1.3, mode: 2, color: '#00FF00'));
    }
    comments.add(const DanmakuComment(text: '高亮弹幕', time: 1.1, border: true, color: '#FFD700'));

    DanmakuLayerStats? last;
    var maxScroll = 0;
    var anyOverlap = false;
    await tester.pumpWidget(_host(PlayerDanmakuLayer(
      filmId: '1',
      episode: 1,
      filmTitle: 't',
      currentTime: 0.9,
      isPlaying: true,
      debugComments: comments,
      debugOnFrame: (s) {
        last = s;
        if (s.scroll > maxScroll) maxScroll = s.scroll;
        if (s.hasOverlap) anyOverlap = true;
      },
    )));
    await tester.pump();
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(last, isNotNull);
    // 旧实现横屏最多 5 行（同屏约 10 条），这里应明显更多且不重叠
    expect(maxScroll, greaterThan(12));
    expect(last!.top, 3);
    expect(last!.bottom, 3);
    expect(last!.highlighted, 1);
    expect(last!.colored, greaterThanOrEqualTo(7));
    expect(anyOverlap, isFalse);

    // 固定弹幕约 4 秒后消失
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(last!.top, 0);
    expect(last!.bottom, 0);
  });

  for (final size in const [Size(390, 220), Size(360, 203), Size(844, 390)]) {
    testWidgets('no vertical/horizontal text overlap in a ${size.width.toInt()}x${size.height.toInt()} player', (tester) async {
      final comments = <DanmakuComment>[];
      for (var i = 0; i < 200; i++) {
        comments.add(DanmakuComment(
          text: i.isEven ? '重叠检测弹幕$i' : 'Overlap check $i 国',
          time: 0.5 + i / 100.0,
          border: i % 7 == 0,
          color: i % 3 == 0 ? '#FF6600' : '#FFFFFF',
        ));
      }
      var anyOverlap = false;
      var maxScroll = 0;
      await tester.pumpWidget(_host(PlayerDanmakuLayer(
        filmId: '1',
        episode: 1,
        filmTitle: 't',
        currentTime: 0.4,
        isPlaying: true,
        debugComments: comments,
        debugOnFrame: (s) {
          if (s.hasOverlap) anyOverlap = true;
          if (s.scroll > maxScroll) maxScroll = s.scroll;
        },
      ), size: size));
      await tester.pump();
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(maxScroll, greaterThan(5));
      expect(anyOverlap, isFalse);
    });
  }

  testWidgets('disabled layer renders nothing', (tester) async {
    await tester.pumpWidget(_host(const PlayerDanmakuLayer(
      filmId: '1',
      episode: 1,
      filmTitle: 't',
      currentTime: 0,
      isPlaying: true,
      enabled: false,
      debugComments: [DanmakuComment(text: 'x', time: 0.1)],
    )));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CustomPaint).evaluate().where((e) => e.widget is CustomPaint && (e.widget as CustomPaint).painter != null), isEmpty);
  });

  testWidgets('滚动弹幕从播放器容器右沿进入、左沿离开，容器尺寸变化后按新宽度进场', (tester) async {
    final comments = <DanmakuComment>[
      const DanmakuComment(text: '进场', time: 0.5),
      for (var i = 0; i < 6; i++) DanmakuComment(text: '换尺寸后$i', time: 9.4 + i * 0.05),
    ];
    final frames = <DanmakuLayerStats>[];
    Widget layer(double t) => PlayerDanmakuLayer(
          filmId: '1',
          episode: 1,
          filmTitle: 't',
          currentTime: t,
          isPlaying: true,
          debugComments: comments,
          debugOnFrame: frames.add,
        );

    await tester.pumpWidget(_host(layer(0.4), size: const Size(600, 300)));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final firstSeen = frames.firstWhere((s) => s.scroll > 0);
    // 刚进场时贴着容器右沿（一帧只走几像素）
    expect(firstSeen.maxScrollX!, greaterThan(600 - 20));
    expect(firstSeen.maxScrollX!, lessThanOrEqualTo(600));

    // 一直走到容器左沿之外才移除，不会在容器内部提前消失
    for (var i = 0; i < 500; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final xs = frames.where((s) => s.minScrollX != null).map((s) => s.minScrollX!);
    expect(xs.reduce(math.min), lessThan(0));

    // 换成更宽的容器（如进入全屏 / 横屏分栏切换），之后到点的弹幕从新的右沿进场
    await tester.pumpWidget(_host(layer(9.0), size: const Size(600, 300)));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(_host(layer(9.05), size: const Size(780, 300)));
    frames.clear();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final seen = frames.where((s) => s.maxScrollX != null).map((s) => s.maxScrollX!);
    expect(seen, isNotEmpty);
    final wide = seen.reduce(math.max);
    expect(wide, greaterThan(780 - 20));
    expect(wide, lessThanOrEqualTo(780));
  });
}
