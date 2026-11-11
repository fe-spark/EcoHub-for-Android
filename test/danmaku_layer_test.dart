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
}
