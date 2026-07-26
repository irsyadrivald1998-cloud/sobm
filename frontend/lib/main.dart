import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'theme_notifier.dart';
import 'activity_log_notifier.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'activity_log_page.dart';
import 'admin_dashboard_page.dart';
import 'profile_page.dart';
import 'attendance_page.dart';
import 'access_denied_page.dart';
import 'forgot_password_page.dart';
import 'leave_submission_page.dart';
import 'offline_queue_page.dart';
import 'crash_reporting_service.dart';
import 'notification_service.dart';
import 'notifications_page.dart';
import 'my_tasks_page.dart';
import 'register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize crash reporting
  await CrashReportingService().initialize();
  
  // Initialize notification service
  await NotificationService().initialize();
  
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
  final NotificationService _notificationService = NotificationService();

  @override
  void dispose() {
    _logNotifier.dispose();
    _themeNotifier.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActivityLogProvider(
      notifier: _logNotifier,
      child: ThemeProvider(
        notifier: _themeNotifier,
        child: NotificationProvider(
          notifier: _notificationService,
          child: AnimatedBuilder(
            animation: _themeNotifier,
            builder: (context, child) {
              return MaterialApp(
                title: 'SOBM Mobile Check-In',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system,
                initialRoute: '/',
                routes: {
                  '/': (context) => const LoginPage(),
                  '/home': (context) => const HomePage(),
                  '/activity-log': (context) => const ActivityLogPage(),
                  '/admin-dashboard': (context) => const AdminDashboardPage(),
                  '/profile': (context) => const ProfilePage(),
                  '/attendance': (context) => const AttendancePage(),
                  '/access-denied': (context) => const AccessDeniedPage(),
                  '/forgot-password': (context) => const ForgotPasswordPage(),
                  '/leave-submission': (context) => const LeaveSubmissionPage(),
                  '/offline-queue': (context) => const OfflineQueuePage(),
                  '/notifications': (context) => const NotificationsPage(),
                  '/my-tasks': (context) => const MyTasksPage(),
                  '/register': (context) => const RegisterPage(),
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── InheritedWidget wrappers ──────────────────────────────────────────────────

class ActivityLogProvider extends InheritedWidget {
  final ActivityLogNotifier notifier;

  const ActivityLogProvider({
    super.key,
    required this.notifier,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant ActivityLogProvider oldWidget) =>
      notifier != oldWidget.notifier;

  static ActivityLogNotifier of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<ActivityLogProvider>();
    assert(p != null, 'No ActivityLogProvider found');
    return p!.notifier;
  }
}

class ThemeProvider extends InheritedWidget {
  final ThemeNotifier notifier;

  const ThemeProvider({
    super.key,
    required this.notifier,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant ThemeProvider oldWidget) =>
      notifier != oldWidget.notifier;

  static ThemeNotifier of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(p != null, 'No ThemeProvider found');
    return p!.notifier;
  }
}

class NotificationProvider extends InheritedWidget {
  final NotificationService notifier;

  const NotificationProvider({
    super.key,
    required this.notifier,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant NotificationProvider oldWidget) =>
      notifier != oldWidget.notifier;

  static NotificationService of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<NotificationProvider>();
    assert(p != null, 'No NotificationProvider found');
    return p!.notifier;
  }
}
