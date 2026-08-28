import 'package:flutter/material.dart';
import '../common/app_theme.dart';
import '../utils/server_config_manager.dart';
import '../utils/source_guard.dart';
import '../utils/site_heartbeat.dart';
import '../api/http_client.dart';
import '../api/film_api.dart';

/// 软件源配置页面
class ServerConfigPage extends StatefulWidget {
  final String mode;

  const ServerConfigPage({super.key, this.mode = ''});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<String> _serverHistory = [];
  bool _reconnect = false;

  @override
  void initState() {
    super.initState();
    _reconnect = widget.mode == 'reconnect';
    _loadInitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    SourceGuard.markClosed();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final url = await ServerConfigManager.instance.getServerUrl();
    _controller.text = url;
    _serverHistory = await ServerConfigManager.instance.getServerHistory();
    if (mounted) setState(() {});
  }

  Future<void> _loadHistory() async {
    final list = await ServerConfigManager.instance.getServerHistory();
    if (mounted) {
      setState(() {
        _serverHistory = list;
      });
    }
  }

  Future<void> _saveAndConnect() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入软件源地址')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final ok = await HttpClient.instance.testConnection(url);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法连接该源，请检查地址')),
      );
      return;
    }

    await ServerConfigManager.instance.setServerUrl(url);
    await _loadHistory();
    FilmApi.clearSiteConfig();
    SiteHeartbeat.instance.resetFailures();

    if (!mounted) return;

    if (_reconnect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重新接入')),
      );
      SourceGuard.markClosed();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
      SourceGuard.notifyReconnected();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('源已接入')),
    );
    SourceGuard.notifyReconnected();
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.bgElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  const Text('历史软件源', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
                  const Spacer(),
                  if (_serverHistory.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ServerConfigManager.instance.clearServerHistory().then((_) {
                          _loadHistory().then((_) {
                            setDialogState(() {});
                          });
                        });
                      },
                      child: const Text('清空', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
                    ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: _serverHistory.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('暂无历史记录', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _serverHistory.length,
                          itemBuilder: (context, index) {
                            final item = _serverHistory[index];
                            final isCurrent = item == _controller.text.trim();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCard,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.link_rounded,
                                  size: 16,
                                  color: isCurrent ? AppTheme.accent : AppTheme.textMuted,
                                ),
                                title: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isCurrent ? AppTheme.accent : AppTheme.textPrimary,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.textMuted),
                                  onPressed: () {
                                    ServerConfigManager.instance.removeServerHistory(item).then((_) {
                                      _loadHistory().then((_) {
                                        setDialogState(() {});
                                      });
                                    });
                                  },
                                ),
                                onTap: () {
                                  _controller.text = item;
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: !_reconnect && Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo & Title
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'EcoHub',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _reconnect ? '软件源连接失败，请检查后重新接入' : '配置软件源后即可观影',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 36),

              // Source Input Area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '软件源地址',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  if (_serverHistory.isNotEmpty)
                    GestureDetector(
                      onTap: _showHistoryDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentSoft,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_rounded, size: 12, color: AppTheme.accent),
                            const SizedBox(width: 4),
                            Text(
                              '历史记录 (${_serverHistory.length})',
                              style: const TextStyle(fontSize: 12, color: AppTheme.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Input Row
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: '请输入软件源地址',
                          hintStyle: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveAndConnect(),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: AppTheme.textMuted),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _saveAndConnect,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _reconnect ? '重新接入' : '开始观影',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '接口形如 https://your-host/api，配置后所有请求均走该源。',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
