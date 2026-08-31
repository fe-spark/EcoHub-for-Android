import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../common/app_theme.dart';
import '../models/film_models.dart';
import '../api/film_api.dart';
import '../utils/format_util.dart';
import '../utils/server_config_manager.dart';
import '../utils/source_guard.dart';
import '../utils/app_version_util.dart';
import '../components/version_update_dialog.dart';

/// 我的 Tab 页面
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  BasicConfig _config = BasicConfig();
  String _sourceUrl = '';
  String _appVersion = '1.0.0';
  bool _isCheckingVersion = false;
  bool _showUpdateDialog = false;
  AppUpdateInfo _updateInfo = AppUpdateInfo(
    currentVersion: '',
    latestVersion: '',
    hasUpdate: false,
    releaseName: '',
    releaseNotes: '',
    releaseUrl: '',
    downloadUrl: '',
  );

  @override
  void initState() {
    super.initState();
    SourceGuard.onReconnect(_onReconnect);
    _initData();
  }

  @override
  void dispose() {
    SourceGuard.offReconnect(_onReconnect);
    super.dispose();
  }

  void _onReconnect() {
    _reload();
  }

  Future<void> _initData() async {
    _appVersion = await AppVersionUtil.getVersionName();
    _checkUpdateSilent();
    await _reload();
  }

  Future<void> _checkUpdateSilent() async {
    try {
      final info = await AppVersionUtil.checkUpdate(force: false);
      if (mounted) {
        setState(() {
          _updateInfo = info;
        });
      }
    } catch (_) {}
  }

  Future<void> _reload() async {
    final url = await ServerConfigManager.instance.getServerUrl();
    try {
      final config = await FilmApi.getSiteConfig(force: false);
      if (mounted) {
        setState(() {
          _sourceUrl = url;
          _config = config;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sourceUrl = url;
        });
      }
    }
  }

  Future<void> _handleCheckVersion({bool force = false}) async {
    if (_isCheckingVersion) return;

    if (!force && _updateInfo.hasUpdate) {
      setState(() {
        _showUpdateDialog = true;
      });
      return;
    }

    setState(() {
      _isCheckingVersion = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在检查版本更新...')),
    );

    try {
      final info = await AppVersionUtil.checkUpdate(force: true);
      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _isCheckingVersion = false;
      });

      if (info.hasUpdate) {
        setState(() {
          _showUpdateDialog = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('当前已是最新版本 (v$_appVersion)')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingVersion = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('检查版本失败，请稍后重试')),
      );
    }
  }

  String _sourceHost() {
    if (_sourceUrl.isEmpty) return '未配置';
    var host = ServerConfigManager.stripApiSuffix(
      ServerConfigManager.instance.normalizeRaw(_sourceUrl),
    );
    if (host.startsWith('https://')) {
      host = host.substring(8);
    } else if (host.startsWith('http://')) {
      host = host.substring(7);
    }
    return host.isNotEmpty ? host : '未配置';
  }

  String _logoLetter() {
    return _config.siteName.isNotEmpty ? _config.siteName.substring(0, 1) : 'E';
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    String extra = '',
    bool hasBadge = false,
    String badgeText = '',
    bool extraHighlight = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 18, color: AppTheme.accent),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (hasBadge) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        badgeText.isNotEmpty ? badgeText : 'NEW',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (extra.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  extra,
                  style: TextStyle(
                    fontSize: 13,
                    color: extraHighlight ? AppTheme.accent : AppTheme.textMuted,
                    fontWeight: extraHighlight ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = ServerConfigManager.instance.resolveMediaUrl(_config.logo);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title
                  Container(
                    height: 48,
                    alignment: Alignment.centerLeft,
                    child: const Row(
                      children: [
                        Icon(Icons.person_rounded, color: AppTheme.accent, size: 20),
                        SizedBox(width: AppTheme.spaceSm),
                        Text(
                          '我的',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Site Info Card
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/server_config').then((_) => _reload());
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceLg),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x47FA8C16),
                            AppTheme.bgCard,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          if (logoUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              child: CachedNetworkImage(
                                imageUrl: logoUrl,
                                httpHeaders: FormatUtil.imageHeaders(logoUrl),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => _buildLogoLetter(),
                              ),
                            )
                          else
                            _buildLogoLetter(),
                          const SizedBox(width: AppTheme.spaceMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _config.siteName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '当前软件源',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _sourceHost(),
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),

                  // Menu list Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Column(
                      children: [
                        _buildMenuRow(
                          icon: Icons.history_rounded,
                          title: '观看历史',
                          onTap: () => Navigator.pushNamed(context, '/history'),
                        ),
                        const Divider(color: AppTheme.border, height: 0.5, indent: 64),
                        _buildMenuRow(
                          icon: Icons.play_circle_fill_rounded,
                          title: '自定义播放',
                          onTap: () => Navigator.pushNamed(context, '/custom_player'),
                        ),
                        if (_config.tipEnabled) ...[
                          const Divider(color: AppTheme.border, height: 0.5, indent: 64),
                          _buildMenuRow(
                            icon: Icons.card_giftcard_rounded,
                            title: _config.tipTitle.isNotEmpty ? _config.tipTitle : '赞赏支持',
                            onTap: () => Navigator.pushNamed(context, '/tip'),
                          ),
                        ],
                        const Divider(color: AppTheme.border, height: 0.5, indent: 64),
                        _buildMenuRow(
                          icon: Icons.update_rounded,
                          title: '版本检查',
                          extra: _isCheckingVersion
                              ? '检查中...'
                              : (_updateInfo.hasUpdate
                                  ? '发现新版本 v${_updateInfo.latestVersion}'
                                  : 'v$_appVersion'),
                          hasBadge: _updateInfo.hasUpdate,
                          extraHighlight: _updateInfo.hasUpdate,
                          onTap: () => _handleCheckVersion(force: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Version Update Modal
          if (_showUpdateDialog)
            VersionUpdateDialog(
              updateInfo: _updateInfo,
              onClose: () {
                setState(() {
                  _showUpdateDialog = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLogoLetter() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Center(
        child: Text(
          _logoLetter(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
