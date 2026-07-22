import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'activity_log_notifier.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'activity_log_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Single shared instance — lives as long as the app
  final ActivityLogNotifier _logNotifier = ActivityLogNotifier();

  @override
  void dispose() {
    _logNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActivityLogProvider(
      notifier: _logNotifier,
      child: MaterialApp(
        title: 'SOBM Mobile Check-In',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/',
        routes: {
          '/':             (context) => const LoginPage(),
          '/home':         (context) => const HomePage(),
          '/activity-log': (context) => const ActivityLogPage(),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  InheritedWidget wrapper — lets any widget in the tree access the notifier
// ─────────────────────────────────────────────────────────────────────────────
class ActivityLogProvider extends InheritedNotifier<ActivityLogNotifier> {
  const ActivityLogProvider({
    super.key,
    required ActivityLogNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ActivityLogNotifier of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ActivityLogProvider>();
    assert(provider != null, 'No ActivityLogProvider found in widget tree');
    return provider!.notifier!;
  }
}
