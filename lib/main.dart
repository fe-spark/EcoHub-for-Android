import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common/app_theme.dart';
import 'utils/app_orientation.dart';
import 'utils/source_guard.dart';
import 'pages/splash_page.dart';
import 'pages/main_scaffold_page.dart';
import 'pages/server_config_page.dart';
import 'pages/filter_page.dart';
import 'pages/search_page.dart';
import 'pages/history_page.dart';
import 'pages/favorite_page.dart';
import 'pages/tip_page.dart';
import 'pages/custom_player_page.dart';
import 'pages/play_page.dart';
import 'pages/about_page.dart';
import 'pages/settings_page.dart';
import 'services/route_observer.dart';
import 'utils/server_config_manager.dart';
import 'utils/history_manager.dart';
import 'utils/site_heartbeat.dart';
import 'utils/app_settings_manager.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 沉浸式透明状态栏与边缘到边缘布局，底栏导航色对齐 OHOS #12141C
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF12141C),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 对齐 OHOS `AUTO_ROTATION_RESTRICTED`：默认自动旋转（竖屏 + 左右横屏，排除倒置）
  SystemChrome.setPreferredOrientations(kAutoRotationOrientations);

  SourceGuard.navigatorKey = appNavigatorKey;

  // 对齐 OHOS EntryAbility.onWindowStageCreate 初始化管线
  await Future.wait([
    ServerConfigManager.instance.init(),
    AppSettingsManager.instance.init(),
  ]);
  await HistoryManager.migrateLegacy();

  runApp(const EcoHubApp());
}

/// 全局根组件，对齐 OHOS EntryAbility 前后台事件全局调度 SiteHeartbeat
class EcoHubApp extends StatefulWidget {
  const EcoHubApp({super.key});

  @override
  State<EcoHubApp> createState() => _EcoHubAppState();
}

class _EcoHubAppState extends State<EcoHubApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SiteHeartbeat.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (ServerConfigManager.instance.getCachedServerUrl().isNotEmpty) {
        SiteHeartbeat.instance.start();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      SiteHeartbeat.instance.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoHub',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      navigatorObservers: [EcoHubRouteObserver()],
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        Widget page;
        switch (settings.name) {
          case '/':
            page = const SplashPage();
            break;
          case '/main':
            page = const MainScaffoldPage();
            break;
          case '/server_config':
            page = ServerConfigPage(
              mode: args['mode'] ?? '',
            );
            break;
          case '/filter':
            page = FilterPage(
              pid: args['Pid'] ?? args['pid'] ?? '',
              category: args['Category'] ?? '',
              sort: args['Sort'] ?? '',
            );
            break;
          case '/search':
            page = SearchPage(
              initialKeyword: args['keyword'] ?? '',
            );
            break;
          case '/history':
            page = const HistoryPage();
            break;
          case '/favorite':
            page = const FavoritePage();
            break;
          case '/tip':
            page = const TipPage();
            break;
          case '/custom_player':
            page = CustomPlayerPage(url: args['url'] ?? '');
            break;
          case '/play':
            page = PlayPage(
              id: args['id'] ?? '',
              sourceId: args['sourceId'] ?? '',
              episodeIndex: int.tryParse('${args['episodeIndex']}') ?? 0,
              currentTime: double.tryParse('${args['currentTime']}') ?? 0,
            );
            break;
          case '/about':
            page = const AboutPage();
            break;
          case '/settings':
            page = const SettingsPage();
            break;
          default:
            page = const SplashPage();
        }

        return MaterialPageRoute(settings: settings, builder: (_) => page);
      },
    );
  }
}
