import 'package:flutter/material.dart';
import '../models/film_models.dart';

/// 统一格式化工具类
class FormatUtil {
  static String text(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final s = '$value'.trim();
    if (s.isEmpty || s == '0') return fallback;
    return s;
  }

  static String year(dynamic value) {
    final s = text(value);
    return s.length >= 4 ? s.substring(0, 4) : s;
  }

  static String poster(MovieBasicInfo film) {
    if (film.picture.isNotEmpty) return film.picture;
    if (film.poster.isNotEmpty) return film.poster;
    if (film.pictureSlide.isNotEmpty) return film.pictureSlide;
    return '';
  }

  static String bannerPoster(BannerItem item) {
    if (item.poster.isNotEmpty) return item.poster;
    if (item.picture.isNotEmpty) return item.picture;
    if (item.pictureSlide.isNotEmpty) return item.pictureSlide;
    return '';
  }

  static String bannerBackdrop(BannerItem item) {
    if (item.pictureSlide.isNotEmpty) return item.pictureSlide;
    if (item.picture.isNotEmpty) return item.picture;
    if (item.poster.isNotEmpty) return item.poster;
    return '';
  }

  static String filmId(MovieBasicInfo film) {
    if (film.id > 0) return '${film.id}';
    return text(film.mid);
  }

  static String pad2(int value) {
    return value < 10 ? '0$value' : '$value';
  }

  static String duration(double seconds) {
    final total = seconds <= 0 ? 0 : seconds.floor();
    final hour = total ~/ 3600;
    final minute = (total % 3600) ~/ 60;
    final second = total % 60;
    if (hour > 0) {
      return '${pad2(hour)}:${pad2(minute)}:${pad2(second)}';
    }
    return '${pad2(minute)}:${pad2(second)}';
  }

  static String progress(double current, double duration) {
    if (current <= 0) return '未观看';
    if (duration <= 0) return '观看至 ${FormatUtil.duration(current)}';
    if (current >= duration - 2) return '已看完';
    final percent = ((current / duration) * 100).floor().clamp(1, 99);
    return '观看至 ${FormatUtil.duration(current)} ($percent%)';
  }

  static String dateTime(int stamp) {
    if (stamp <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(stamp);
    return '${dt.year}-${pad2(dt.month)}-${pad2(dt.day)} ${pad2(dt.hour)}:${pad2(dt.minute)}';
  }

  static String joinMeta(List<String> parts) {
    final items = <String>[];
    for (final p in parts) {
      final t = p.trim();
      if (t.isNotEmpty) items.add(t);
    }
    return items.join(' · ');
  }

  static const List<Color> _tagBg = [
    Color(0x47FA8C16), // rgba(250, 140, 22, 0.28)
    Color(0x4760A5FA), // rgba(96, 165, 250, 0.28)
    Color(0x4734D399), // rgba(52, 211, 153, 0.28)
    Color(0x47A78BFA), // rgba(167, 139, 250, 0.28)
    Color(0x47FB7185), // rgba(251, 113, 133, 0.28)
    Color(0x4722D3EE), // rgba(34, 211, 238, 0.28)
    Color(0x47FACC15), // rgba(250, 204, 21, 0.28)
    Color(0x47818CF8), // rgba(129, 140, 248, 0.28)
  ];

  static const List<Color> _tagBorder = [
    Color(0x7AFA8C16), // rgba(250, 140, 22, 0.48)
    Color(0x7A60A5FA), // rgba(96, 165, 250, 0.48)
    Color(0x7A34D399), // rgba(52, 211, 153, 0.48)
    Color(0x7AA78BFA), // rgba(167, 139, 250, 0.48)
    Color(0x7AFB7185), // rgba(251, 113, 133, 0.48)
    Color(0x7A22D3EE), // rgba(34, 211, 238, 0.48)
    Color(0x7AFACC15), // rgba(250, 204, 21, 0.48)
    Color(0x7A818CF8), // rgba(129, 140, 248, 0.48)
  ];

  static int _tagIndex(int id, String name) {
    int hash = id * 7;
    for (int i = 0; i < name.length; i++) {
      hash = (hash * 33 + name.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash % _tagBg.length;
  }

  static Color tagBg(int id, [String name = '']) {
    return _tagBg[_tagIndex(id, name)];
  }

  static Color tagBorder(int id, [String name = '']) {
    return _tagBorder[_tagIndex(id, name)];
  }
}
