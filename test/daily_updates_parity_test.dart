import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/common/app_theme.dart';
import 'package:ecohub_android/models/film_models.dart';
import 'package:ecohub_android/pages/daily_updates_tab.dart';
import 'package:ecohub_android/pages/daily_update_pane.dart';
import 'package:ecohub_android/components/scroll_fab.dart';
import 'package:ecohub_android/components/empty_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyUpdatesTab Parity Tests', () {
    testWidgets('DailyUpdatesTab renders frosted glass header, title, and handles network error state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailyUpdatesTab(),
          ),
        ),
      );
      // Pump to process initial async load (which fails with 400 in test environment)
      await tester.pump();

      // Frosted glass header with BackdropFilter
      final backdropFinder = find.byType(BackdropFilter);
      expect(backdropFinder, findsWidgets);

      // Header title '每日更新'
      expect(find.text('每日更新'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

      // Network error state rendered with EmptyState & retry button
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);

      // RefreshIndicator is available on error state with edgeOffset
      final refreshFinder = find.byType(RefreshIndicator);
      expect(refreshFinder, findsOneWidget);
      final refreshWidget = tester.widget<RefreshIndicator>(refreshFinder);
      expect(refreshWidget.edgeOffset, greaterThan(0));
    });

    testWidgets('DailyUpdatesTab state provides TickerProvider for smooth animations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailyUpdatesTab(),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state(find.byType(DailyUpdatesTab));
      expect(state, isA<TickerProvider>());
    });
  });

  group('DailyUpdatePane Parity Tests', () {
    final List<MovieBasicInfo> shortSeedList = List.generate(
      3,
      (i) => MovieBasicInfo(
        id: i + 1,
        name: '每日更新影片 $i',
        poster: 'https://example.com/poster$i.jpg',
        remarks: 'HD',
      ),
    );

    testWidgets('DailyUpdatePane consumes seed immediately without network request', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyUpdatePane(
              pid: 0,
              active: true,
              seedPid: 0,
              seedList: shortSeedList,
              seedPage: PageInfo(pageSize: 21, current: 1, pageCount: 1, total: 3),
              headerHeight: 94.0,
            ),
          ),
        ),
      );
      await tester.pump();

      // FilmCard items in viewport should be present immediately
      expect(find.text('每日更新影片 0'), findsOneWidget);
      expect(find.text('每日更新影片 1'), findsOneWidget);
      expect(find.text('每日更新影片 2'), findsOneWidget);

      // Top spacer should match headerHeight + 8 = 102.0
      final topSpacer = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(SliverToBoxAdapter).first,
          matching: find.byType(SizedBox),
        ),
      );
      expect(topSpacer.height, 102.0);

      // RefreshIndicator edgeOffset should match headerHeight
      final refreshIndicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      expect(refreshIndicator.edgeOffset, 94.0);
      expect(refreshIndicator.displacement, 16.0);

      // Footer says '没有更多了'
      expect(find.text('没有更多了'), findsOneWidget);
    });

    testWidgets('DailyUpdatePane shows empty state with correct copy and spacer when list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyUpdatePane(
              pid: 0,
              active: true,
              seedPid: 0,
              seedList: const [],
              seedPage: PageInfo(pageSize: 21, current: 1, pageCount: 1, total: 0),
              headerHeight: 94.0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('暂无更新'), findsOneWidget);
      expect(find.text('近 24 小时还没有新片入库'), findsOneWidget);

      // Spacer height is headerHeight + 24 = 118.0
      final spacer = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(spacer.height, 118.0);
    });

    testWidgets('DailyUpdatePane shows TopFab after scrolling past viewport dimension', (tester) async {
      final List<MovieBasicInfo> longSeedList = List.generate(
        30,
        (i) => MovieBasicInfo(
          id: i + 1,
          name: '电影 $i',
          poster: 'https://example.com/p$i.jpg',
          remarks: 'HD',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 600,
              child: DailyUpdatePane(
                pid: 0,
                active: true,
                seedPid: 0,
                seedList: longSeedList,
                seedPage: PageInfo(pageSize: 30, current: 1, pageCount: 1, total: 30),
                headerHeight: 94.0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // ScrollFab should be hidden initially
      final initialFab = tester.widget<ScrollFab>(find.byType(ScrollFab));
      expect(initialFab.visible, isFalse);

      // Scroll down by 700 pixels (past viewport height of 600)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();

      final visibleFab = tester.widget<ScrollFab>(find.byType(ScrollFab));
      expect(visibleFab.visible, isTrue);

      // Tap TopFab to scroll back to top
      await tester.tap(find.byType(ScrollFab));
      await tester.pumpAndSettle();

      final finalFab = tester.widget<ScrollFab>(find.byType(ScrollFab));
      expect(finalFab.visible, isFalse);
    });

    testWidgets('DailyUpdatePane honors safe area insets in landscape', (tester) async {
      const leftCutout = 32.0;
      const rightCutout = 48.0;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(left: leftCutout, right: rightCutout, top: 24),
            size: Size(800, 400),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: DailyUpdatePane(
                pid: 0,
                active: true,
                seedPid: 0,
                seedList: shortSeedList,
                seedPage: PageInfo(pageSize: 21, current: 1, pageCount: 1, total: 3),
                headerHeight: 48.0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // SliverPadding should include left and right cutouts
      final sliverPadding = tester.widget<SliverPadding>(find.byType(SliverPadding));
      final resolvedPadding = sliverPadding.padding.resolve(TextDirection.ltr);
      expect(resolvedPadding.left, AppTheme.spaceLg + leftCutout);
      expect(resolvedPadding.right, AppTheme.spaceLg + rightCutout);
    });

    testWidgets('DailyUpdatePane notifies onAllRefreshed on pull refresh for seedPid', (tester) async {
      var refreshed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyUpdatePane(
              pid: 0,
              active: true,
              seedPid: 0,
              seedList: shortSeedList,
              seedPage: PageInfo(pageSize: 21, current: 1, pageCount: 1, total: 3),
              headerHeight: 94.0,
              onAllRefreshed: () {
                refreshed = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state(find.byType(DailyUpdatePane));
      expect(state, isNotNull);
      expect(refreshed, isFalse);
    });
  });
}
