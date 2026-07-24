import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

enum NotificationType {
  schedule,  // Jadwal baru
  reminder,  // Pengingat tugas
  issue,     // Kendala/issue baru
  report,    // Laporan baru dari rekan
  system,    // System notification
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  Timer? _pollTimer;
  final ApiService _apiService = ApiService();

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  Future<void> initialize() async {
    await _loadFromStorage();
    
    // Start polling every 2 minutes for new notifications
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _checkForNewNotifications();
    });

    // Check immediately on init
    _checkForNewNotifications();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      
      _notifications.clear();
      for (final json in notificationsJson) {
        try {
          final notif = AppNotification.fromJson(jsonDecode(json));
          _notifications.add(notif);
        } catch (e) {
          debugPrint('Error parsing notification: $e');
        }
      }
      
      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Keep only last 50 notifications
      if (_notifications.length > 50) {
        _notifications.removeRange(50, _notifications.length);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> _checkForNewNotifications() async {
    try {
      // Check for upcoming schedules
      final schedules = await _apiService.getSchedules();
      _checkUpcomingSchedules(schedules);
      
      // Check for new reports (from activity log)
      // This is already handled by activity_log_page polling
      
    } catch (e) {
      debugPrint('Error checking notifications: $e');
    }
  }

  void _checkUpcomingSchedules(List<dynamic> schedules) {
    final now = DateTime.now();
    
    for (final schedule in schedules) {
      final status = schedule['status'] as String?;
      if (status != 'pending') continue;
      
      final shiftDate = schedule['shift_date'] as String?;
      final scheduledTime = schedule['scheduled_time'] as String?;
      
      if (shiftDate == null || scheduledTime == null) continue;
      
      try {
        final dateTime = DateTime.parse('$shiftDate $scheduledTime:00');
        final diff = dateTime.difference(now);
        
        // Notify if schedule is within 30 minutes
        if (diff.inMinutes > 0 && diff.inMinutes <= 30) {
          final checkpoint = schedule['checkpoint'] as Map<String, dynamic>? ?? {};
          final checkpointName = checkpoint['name'] ?? 'Checkpoint';
          
          final notifId = 'schedule_${schedule['id']}';
          
          // Check if notification already exists
          if (!_notifications.any((n) => n.id == notifId)) {
            addNotification(
              AppNotification(
                id: notifId,
                type: NotificationType.reminder,
                title: '⏰ Pengingat Tugas',
                body: 'Tugas di $checkpointName akan dimulai dalam ${diff.inMinutes} menit',
                timestamp: now,
                data: {'schedule_id': schedule['id']},
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error parsing schedule time: $e');
      }
    }
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    
    // Keep only last 50
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
    
    _saveToStorage();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveToStorage();
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // Helper to create notifications from different sources
  void notifyNewSchedule(Map<String, dynamic> schedule) {
    final checkpoint = schedule['checkpoint'] as Map<String, dynamic>? ?? {};
    addNotification(
      AppNotification(
        id: 'schedule_new_${schedule['id']}_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.schedule,
        title: '📋 Jadwal Baru',
        body: 'Anda memiliki tugas baru di ${checkpoint['name']}',
        timestamp: DateTime.now(),
        data: {'schedule_id': schedule['id']},
      ),
    );
  }

  void notifyNewIssue(Map<String, dynamic> issue) {
    addNotification(
      AppNotification(
        id: 'issue_${issue['id']}_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.issue,
        title: '⚠️ Kendala Baru',
        body: issue['description'] as String? ?? 'Kendala baru terdeteksi',
        timestamp: DateTime.now(),
        data: {'issue_id': issue['id']},
      ),
    );
  }

  void notifyNewReport(String message) {
    addNotification(
      AppNotification(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.report,
        title: '📄 Aktivitas Baru',
        body: message,
        timestamp: DateTime.now(),
      ),
    );
  }
}
