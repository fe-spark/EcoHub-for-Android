import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/components/player/player_scale.dart';
import 'package:ecohub_android/components/player/player_video_surface.dart';

void main() {
  group('弹幕层按视频实际画面定位', () {
    test('全屏宽屏播放 16:9 视频：左右黑边不算画面', () {
      final r = PlayerVideoSurface.displayRect(const Size(2000, 900), 16 / 9, PlayerScaleMode.fit);
      expect(r.height, 900);
      expect(r.width, closeTo(1600, 1e-6));
      expect(r.left, closeTo(200, 1e-6));
      expect(r.right, closeTo(1800, 1e-6));
      expect(r.top, 0);
    });

    test('横屏分栏较窄的播放器：上下黑边不算画面', () {
      final r = PlayerVideoSurface.displayRect(const Size(500, 400), 16 / 9, PlayerScaleMode.fit);
      expect(r.width, 500);
      expect(r.height, closeTo(281.25, 1e-6));
      expect(r.top, closeTo(59.375, 1e-6));
      expect(r.left, 0);
    });

    test('填充 / 拉伸铺满整个播放器，宽高比未知时也按整个播放器', () {
      const box = Size(2000, 900);
      expect(PlayerVideoSurface.displayRect(box, 16 / 9, PlayerScaleMode.cover), Offset.zero & box);
      expect(PlayerVideoSurface.displayRect(box, 16 / 9, PlayerScaleMode.stretch), Offset.zero & box);
      expect(PlayerVideoSurface.displayRect(box, null, PlayerScaleMode.fit), Offset.zero & box);
    });
  });
}
