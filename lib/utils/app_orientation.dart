import 'dart:math' as math;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局默认屏幕方向，对齐 OHOS `window.Orientation.AUTO_ROTATION_RESTRICTED`
/// （竖屏 + 左右横屏，排除倒置竖屏）。
const List<DeviceOrientation> kAutoRotationOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

/// 手机端默认屏幕方向（锁定竖屏，仅全屏播放器允许横屏）
const List<DeviceOrientation> kPhoneDefaultOrientations = [
  DeviceOrientation.portraitUp,
];

class AppOrientation {
  /// 是否为平板设备（根据最小边 >= 560 判定）
  static bool isTablet([BuildContext? context]) {
    if (context != null && context.mounted) {
      try {
        final size = MediaQuery.maybeSizeOf(context);
        if (size != null && size.width > 0 && size.height > 0) {
          return math.min(size.width, size.height) >= 560;
        }
      } catch (_) {}
    }
    final view = PlatformDispatcher.instance.views.firstOrNull;
    if (view != null && view.devicePixelRatio > 0) {
      final size = view.physicalSize / view.devicePixelRatio;
      if (size.width > 0 && size.height > 0) {
        return math.min(size.width, size.height) >= 560;
      }
    }
    return false;
  }

  /// 恢复页面或应用默认屏幕方向：
  /// - 手机端：锁定竖屏，杜绝从播放页返回首页时意外旋转成横屏
  /// - 平板端：支持自动旋转
  static Future<void> restoreDefaultOrientation([BuildContext? context]) async {
    final orientations = isTablet(context) ? kAutoRotationOrientations : kPhoneDefaultOrientations;
    try {
      await SystemChrome.setPreferredOrientations(orientations);
    } catch (_) {}
  }
}
