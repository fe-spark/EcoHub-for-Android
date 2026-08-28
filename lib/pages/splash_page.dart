import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../utils/server_config_manager.dart';
import '../api/film_api.dart';

const int _minSplashTimeMs = 800;
const int _probeAttempts = 3;
const int _probeTimeoutMs = 5000;

/// 开屏自检页面
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _statusText = '正在接入服务...';

  @override
  void initState() {
    super.initState();
    _checkAndBootstrap();
  }

  Future<void> _checkAndBootstrap() async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    await ServerConfigManager.instance.init();
    final url = await ServerConfigManager.instance.getServerUrl();

    if (url.trim().isEmpty) {
      await _ensureMinTime(startTime, _minSplashTimeMs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先配置软件源')),
        );
        Navigator.pushReplacementNamed(context, '/server_config');
      }
      return;
    }

    setState(() {
      _statusText = '正在检测软件源连通性...';
    });

    var ok = false;
    for (var i = 0; i < _probeAttempts; i++) {
      if (i > 0) {
        setState(() {
          _statusText = '正在重试软件源连通性 (${i + 1}/$_probeAttempts)...';
        });
      }
      try {
        await FilmApi.getSiteConfig(force: true, timeoutMs: _probeTimeoutMs);
        ok = true;
        break;
      } catch (_) {}
    }

    await _ensureMinTime(startTime, _minSplashTimeMs);

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('软件源连接失败，请检查网络或重新配置')),
      );
      Navigator.pushReplacementNamed(
        context,
        '/server_config',
        arguments: {'mode': 'reconnect'},
      );
    }
  }

  Future<void> _ensureMinTime(int startTime, int minTime) async {
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
    if (elapsed < minTime) {
      await Future.delayed(Duration(milliseconds: minTime - elapsed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'EcoHub',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
