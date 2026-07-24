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
          child: ListenableBuilder(
            listenable: _themeNotifier,
            builder: (_, _) => MaterialApp(
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
              '/attendance':      (context) => const AttendancePage(),
              '/access-denied':   (context) => const AccessDeniedPage(),
              '/forgot-password': (context) => const ForgotPasswordPage(),
              '/leave-submission': (context) => const LeaveSubmissionPage(),
              '/offline-queue':   (context) => const OfflineQueuePage(),
              '/notifications':   (context) => const NotificationsPage(),
              '/my-tasks':        (context) => const MyTasksPage(),
            },
            ),
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
  
  static ActivityLogNotifier? maybeOf(BuildContext context) {
    try {
      return context.dependOnInheritedWidgetOfExactType<ActivityLogProvider>()?.notifier;
    } catch (e) {
      return null;
    }
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
  
  static ThemeNotifier? maybeOf(BuildContext context) {
    try {
      return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()?.notifier;
    } catch (e) {
      return null;
    }
  }
}

class NotificationProvider extends InheritedNotifier<NotificationService> {
  const NotificationProvider({
    super.key,
    required NotificationService notifier,
    required super.child,
  }) : super(notifier: notifier);

  static NotificationService of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<NotificationProvider>();
    assert(p != null, 'No NotificationProvider found');
    return p!.notifier!;
  }
  
  static NotificationService? maybeOf(BuildContext context) {
    try {
      return context.dependOnInheritedWidgetOfExactType<NotificationProvider>()?.notifier;
    } catch (e) {
      return null;
    }
  }
}
