import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sobm/login_page.dart';

void main() {
  testWidgets('LoginPage displays login form fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Masuk'), findsWidgets);
  });
}
