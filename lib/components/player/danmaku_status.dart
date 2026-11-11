import 'package:flutter/material.dart';
import '../../models/film_models.dart';

/// 状态点颜色：加载中 / 正常 / 没有全网弹幕 / 失败；none 不显示状态点
enum DanmakuStatusTone { loading, ok, warn, error, none }

/// 弹幕加载状态，文案与网页端 `danmakuStatus.ts` 保持一致：
/// placeholder 是控制条上的灰字，title 是完整说明（含失败原因），tone 决定状态点颜色。
@immutable
class DanmakuStatus {
  final String placeholder;
  final String title;
  final DanmakuStatusTone tone;

  const DanmakuStatus({required this.placeholder, required this.title, required this.tone});

  /// 没有任何弹幕时沿用的占位文字
  static const String defaultPlaceholder = '发个友善的弹幕见证当下';

  static const DanmakuStatus loading = DanmakuStatus(
    placeholder: '弹幕加载中…',
    title: '弹幕加载中…',
    tone: DanmakuStatusTone.loading,
  );

  /// 接口本身失败（非成功返回码或网络错误）
  factory DanmakuStatus.requestFailed([String? msg]) {
    final reason = (msg == null || msg.isEmpty) ? '未知原因' : msg;
    return DanmakuStatus(placeholder: '弹幕加载失败：$reason', title: '弹幕加载失败：$reason', tone: DanmakuStatusTone.error);
  }

  /// 弹幕列表装载完成后的状态。total 是本站和全网合计条数
  factory DanmakuStatus.loaded(int total, DanmakuMeta? meta) {
    final say = total > 0 ? '共 $total 条弹幕，说点什么吧' : defaultPlaceholder;
    switch (meta?.networkStatus) {
      case 'ok':
        return DanmakuStatus(placeholder: say, title: '已加载 $total 条弹幕（全网 ${meta!.network} 条）', tone: DanmakuStatusTone.ok);
      case 'empty':
        final reason = meta!.networkReason.isNotEmpty ? '：${meta.networkReason}' : '';
        return DanmakuStatus(
          placeholder: total > 0 ? '共 $total 条弹幕，未找到全网弹幕' : '未找到全网弹幕，说点什么吧',
          title: '${total > 0 ? '已加载 $total 条弹幕，' : ''}未找到全网弹幕$reason',
          tone: DanmakuStatusTone.warn,
        );
      case 'error':
        final reason = meta!.networkReason.isNotEmpty ? meta.networkReason : '未知原因';
        return DanmakuStatus(
          placeholder: '全网弹幕加载失败：$reason',
          title: '全网弹幕加载失败：$reason${total > 0 ? '（已加载本站 $total 条）' : ''}',
          tone: DanmakuStatusTone.error,
        );
      default:
        // 没开全网弹幕（或老接口没有 meta）：只报本站条数，不显示状态点
        return DanmakuStatus(placeholder: say, title: total > 0 ? '已加载 $total 条弹幕' : '', tone: DanmakuStatusTone.none);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DanmakuStatus && other.placeholder == placeholder && other.title == title && other.tone == tone;

  @override
  int get hashCode => Object.hash(placeholder, title, tone);
}

/// 6px 状态点，颜色与网页端一致；加载中为半透明白色并闪烁，none 不显示
class DanmakuStatusDot extends StatefulWidget {
  final DanmakuStatusTone tone;

  const DanmakuStatusDot({super.key, required this.tone});

  static Color colorOf(DanmakuStatusTone tone) {
    switch (tone) {
      case DanmakuStatusTone.ok:
        return const Color(0xFF52C41A);
      case DanmakuStatusTone.warn:
        return const Color(0xFFFAAD14);
      case DanmakuStatusTone.error:
        return const Color(0xFFFF4D4F);
      case DanmakuStatusTone.loading:
      case DanmakuStatusTone.none:
        return const Color(0x80FFFFFF);
    }
  }

  @override
  State<DanmakuStatusDot> createState() => _DanmakuStatusDotState();
}

class _DanmakuStatusDotState extends State<DanmakuStatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant DanmakuStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tone != widget.tone) _syncPulse();
  }

  void _syncPulse() {
    if (widget.tone == DanmakuStatusTone.loading) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tone == DanmakuStatusTone.none) return const SizedBox.shrink();
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: DanmakuStatusDot.colorOf(widget.tone), shape: BoxShape.circle),
    );
    if (widget.tone != DanmakuStatusTone.loading) return dot;
    return FadeTransition(opacity: Tween<double>(begin: 0.3, end: 1).animate(_pulse), child: dot);
  }
}
