import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecohub_android/components/search_source_tabs.dart';
import 'package:ecohub_android/models/film_models.dart';

void main() {
  testWidgets('SearchSourceTabs shows count and loading on chips', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchSourceTabs(
            sources: [
              SearchSourceTab(id: '', name: '聚合', count: 8),
              SearchSourceTab(id: 'a', name: '主站', loading: true),
              SearchSourceTab(id: 'b', name: '金鹰', count: 3),
            ],
            activeId: '',
            onChange: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('聚合'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('金鹰'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
