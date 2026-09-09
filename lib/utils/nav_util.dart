import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 路由封装，对齐 OHOS `NavUtil`
class NavUtil {
  static void openFavorite(BuildContext context) {
    Navigator.pushNamed(context, '/favorite');
  }

  static void openHistory(BuildContext context) {
    Navigator.pushNamed(context, '/history');
  }

  static void openTip(BuildContext context) {
    Navigator.pushNamed(context, '/tip');
  }

  static void openPlay(
    BuildContext context,
    String id, {
    String sourceId = '',
    int? episodeIndex,
    double? currentTime,
  }) {
    if (id.isEmpty) return;
    final params = <String, dynamic>{'id': id};
    if (sourceId.isNotEmpty) params['sourceId'] = sourceId;
    if (episodeIndex != null && episodeIndex >= 0) {
      params['episodeIndex'] = '$episodeIndex';
    }
    if (currentTime != null && currentTime >= 0) {
      params['currentTime'] = '$currentTime';
    }
    Navigator.pushNamed(context, '/play', arguments: params);
  }

  static void openFilter(
    BuildContext context,
    String pid, {
    String category = '',
    String sort = '',
  }) {
    Navigator.pushNamed(
      context,
      '/filter',
      arguments: {'Pid': pid, 'Category': category, 'Sort': sort},
    );
  }

  static void openSearch(BuildContext context, [String keyword = '']) {
    if (keyword.isEmpty) {
      Navigator.pushNamed(context, '/search');
      return;
    }
    Navigator.pushNamed(context, '/search', arguments: {'keyword': keyword});
  }

  static void openCustomPlayer(BuildContext context, [String url = '']) {
    if (url.isEmpty) {
      Navigator.pushNamed(context, '/custom_player');
      return;
    }
    Navigator.pushNamed(context, '/custom_player', arguments: {'url': url});
  }

  static Future<void> openBrowser(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static String param(Map<String, dynamic>? params, String key, [String fallback = '']) {
    if (params == null) return fallback;
    final value = params[key];
    if (value == null) return fallback;
    return '$value';
  }
}
