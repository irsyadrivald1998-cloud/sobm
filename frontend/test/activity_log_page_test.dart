import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobm/activity_log_page.dart';
import 'package:sobm/main.dart';
import 'package:sobm/activity_log_notifier.dart';

void main() {
  testWidgets('ActivityLogPage displays list', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ActivityLogProvider(
        notifier: ActivityLogNotifier(),
        child: const ActivityLogPage(),
      ),
    ));
    
    // Check for some expected UI element.
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
