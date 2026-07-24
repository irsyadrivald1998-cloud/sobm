import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'theme_notifier.dart';
import 'activity_log_notifier.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'activity_log_page.dart';
import 'admin_dashboard_page.dart';
import 'profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ActivityLogNotifier _logNotifier   = ActivityLogNotifier();
  final ThemeNotifier        _themeNotifier = ThemeNotifier();

  @override
  void dispose() {
    _logNotifier.dispose();
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActivityLogProvider(
      notifier: _logNotifier,
      child: ThemeProvider(
        notifier: _themeNotifier,
        child: ListenableBuilder(
          listenable: _themeNotifier,
          builder: (_, __) => MaterialApp(
            title: 'SOBM Mobile Check-In',
            debugShowCheckedModeBanner: false,
            theme:      AppTheme.lightTheme,
            darkTheme:  AppTheme.darkTheme,
            themeMode:  _themeNotifier.themeMode,
            initialRoute: '/',
            routes: {
              '/':                (context) => const LoginPage(),
              '/home':            (context) => const HomePage(),
              '/activity-log':    (context) => const ActivityLogPage(),
              '/admin-dashboard': (context) => const AdminDashboardPage(),
              '/profile':         (context) => const ProfilePage(),
            },
          ),
        ),
      ),
    );
  }
}

// ── InheritedWidget wrappers ──────────────────────────────────────────────────

class ActivityLogProvider extends InheritedNotifier<ActivityLogNotifier> {
  const ActivityLogProvider({
    super.key,
    required ActivityLogNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ActivityLogNotifier of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<ActivityLogProvider>();
    assert(p != null, 'No ActivityLogProvider found');
    return p!.notifier!;
  }
}

class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    super.key,
    required ThemeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeNotifier of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(p != null, 'No ThemeProvider found');
    return p!.notifier!;
  }
}
