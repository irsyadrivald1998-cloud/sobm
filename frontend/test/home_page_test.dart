import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobm/home_page.dart';
import 'package:sobm/main.dart';
import 'package:sobm/activity_log_notifier.dart';

void main() {
  testWidgets('HomePage loads dashboard', (WidgetTester tester) async {
    // Need to wrap in required providers
    await tester.pumpWidget(MaterialApp(
      home: ActivityLogProvider(
        notifier: ActivityLogNotifier(),
        child: const HomePage(),
      ),
    ));
    
    // Check for some expected UI element. Without actual data, it might just show loading or error
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
