import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common/app_theme.dart';
import 'utils/source_guard.dart';
import 'pages/splash_page.dart';
import 'pages/main_scaffold_page.dart';
import 'pages/server_config_page.dart';
import 'pages/filter_page.dart';
import 'pages/search_page.dart';
import 'pages/history_page.dart';
import 'pages/tip_page.dart';
import 'pages/custom_player_page.dart';
import 'pages/play_page.dart';
import 'services/route_observer.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 沉浸式透明状态栏
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.bgElevated,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SourceGuard.navigatorKey = appNavigatorKey;

  runApp(const EcoHubApp());
}

class EcoHubApp extends StatelessWidget {
  const EcoHubApp({super.key});

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
          case '/tip':
            page = const TipPage();
            break;
          case '/custom_player':
            page = const CustomPlayerPage();
            break;
          case '/play':
            page = PlayPage(
              id: args['id'] ?? '',
              sourceId: args['sourceId'] ?? '',
              episodeIndex: int.tryParse('${args['episodeIndex']}') ?? 0,
              currentTime: double.tryParse('${args['currentTime']}') ?? 0,
            );
            break;
          default:
            page = const SplashPage();
        }

        return MaterialPageRoute(settings: settings, builder: (_) => page);
      },
    );
  }
}
