import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/components/player/player_bars.dart';
import 'package:ecohub_android/components/player/player_skin_view.dart';
import 'package:ecohub_android/services/server_compat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PlayerBottomBar does not show 弹幕 chip when canDanmaku is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerBottomBar(
            isReady: true,
            isOpening: false,
            showHud: true,
            errorText: '',
            cinemaHud: false,
            isFull: false,
            isPlaying: true,
            muted: false,
            currentPosition: const Duration(seconds: 10),
            totalDuration: const Duration(seconds: 100),
            currentSpeed: 1.0,
            scaleLabel: '适应',
            canDanmaku: false,
            onTogglePlay: () {},
            onToggleFull: () {},
            onToggleMute: () {},
            onSpeed: () {},
            onSeekTo: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('弹幕'), findsNothing);
  });

  testWidgets('PlayerBottomBar shows 弹幕 chip when canDanmaku is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerBottomBar(
            isReady: true,
            isOpening: false,
            showHud: true,
            errorText: '',
            cinemaHud: false,
            isFull: false,
            isPlaying: true,
            muted: false,
            currentPosition: const Duration(seconds: 10),
            totalDuration: const Duration(seconds: 100),
            currentSpeed: 1.0,
            scaleLabel: '适应',
            canDanmaku: true,
            onTogglePlay: () {},
            onToggleFull: () {},
            onToggleMute: () {},
            onSpeed: () {},
            onSeekTo: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('弹幕'), findsOneWidget);
  });

  testWidgets('PlayerSkinView hides 弹幕 chip when canDanmaku is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerSkinView(
            isFull: false,
            showHud: true,
            title: '测试片源',
            isPlaying: true,
            isBuffering: false,
            currentPosition: Duration.zero,
            totalDuration: const Duration(minutes: 10),
            canDanmaku: false,
            onBack: () {},
            onTogglePlay: () {},
            onToggleFull: () {},
            onToggleMute: () {},
            onSpeed: () {},
            onRetry: () {},
            onSeekBack10: () {},
            onSeekFwd10: () {},
            onSeekTo: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('弹幕'), findsNothing);
  });

  test('ServerCompat canDanmaku is only true for v3', () async {
    await ServerCompat.instance.markFallbackV2('test_v2_scope');
    expect(ServerCompat.instance.isV3, isFalse);
    expect(ServerCompat.instance.canDanmaku, isFalse);

    await ServerCompat.instance.updateFromProvideApp({'protocol': 3, 'version': '3.0.0'}, 'test_v2_scope');
    expect(ServerCompat.instance.isV3, isTrue);
    expect(ServerCompat.instance.canDanmaku, isTrue);
  });
}
