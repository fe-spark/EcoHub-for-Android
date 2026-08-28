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
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashPage());
          case '/main':
            return MaterialPageRoute(builder: (_) => const MainScaffoldPage());
          case '/server_config':
            return MaterialPageRoute(
              builder: (_) => ServerConfigPage(
                mode: args['mode'] ?? '',
              ),
            );
          case '/filter':
            return MaterialPageRoute(
              builder: (_) => FilterPage(
                pid: args['Pid'] ?? args['pid'] ?? '',
                category: args['Category'] ?? '',
                sort: args['Sort'] ?? '',
              ),
            );
          case '/search':
            return MaterialPageRoute(
              builder: (_) => SearchPage(
                initialKeyword: args['keyword'] ?? '',
              ),
            );
          case '/history':
            return MaterialPageRoute(builder: (_) => const HistoryPage());
          case '/tip':
            return MaterialPageRoute(builder: (_) => const TipPage());
          case '/custom_player':
            return MaterialPageRoute(builder: (_) => const CustomPlayerPage());
          case '/play':
            return MaterialPageRoute(
              builder: (_) => PlayPage(
                id: args['id'] ?? '',
                sourceId: args['sourceId'] ?? '',
                episodeIndex: int.tryParse('${args['episodeIndex']}') ?? 0,
                currentTime: double.tryParse('${args['currentTime']}') ?? 0,
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const SplashPage());
        }
      },
    );
  }
}
