import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ActivityLogEntry — single timeline item
// ─────────────────────────────────────────────────────────────────────────────
enum LogEntryType { system, user, alert }

class ActivityLogEntry {
  final LogEntryType type;
  final String       actor;
  final String       timestamp;   // "09:30 AM"
  final DateTime     date;
  final String       body;

  // system fields
  final String? photoUrl;
  final String? workOrder;
  final String? source;

  // user fields
  final IconData? avatarIcon;
  final Color?    avatarColor;

  // alert fields
  final String? alertTitle;

  const ActivityLogEntry({
    required this.type,
    required this.actor,
    required this.timestamp,
    required this.date,
    required this.body,
    this.photoUrl,
    this.workOrder,
    this.source,
    this.avatarIcon,
    this.avatarColor,
    this.alertTitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  ActivityLogNotifier — global shared state
// ─────────────────────────────────────────────────────────────────────────────
class ActivityLogNotifier extends ChangeNotifier {
  final List<ActivityLogEntry> _entries = [];

  List<ActivityLogEntry> get entries => List.unmodifiable(_entries);

  // Called on app start / pull-to-refresh to seed entries from API data
  void seedFromApi(List<dynamic> reports, List<dynamic> schedules) {
    _entries.clear();

    for (final r in reports) {
      final report     = r as Map<String, dynamic>;
      final schedule   = report['schedule']    as Map<String, dynamic>? ?? {};
      final checkpoint = schedule['checkpoint'] as Map<String, dynamic>? ?? {};
      final user       = report['user']        as Map<String, dynamic>? ?? {};
      final issue      = report['issue']       as Map<String, dynamic>?;
      final photo      = report['photo_url']   as String?;
      final createdAt  = report['created_at']  as String? ?? '';
      final notes      = report['notes']       as String? ?? '';

      if (photo != null && photo.isNotEmpty) {
        _entries.add(ActivityLogEntry(
          type:      LogEntryType.system,
          actor:     'Sistem BMS',
          timestamp: _fmt(createdAt),
          date:      _parse(createdAt),
          body:      '${user['name'] ?? 'Pekerja'} mengunggah foto di ${checkpoint['name'] ?? 'Checkpoint'}',
          photoUrl:  photo,
          workOrder: 'WO-${report['id'] ?? '0000'}',
          source:    'Ditambahkan via Mobile App',
        ));
      }

      if (notes.isNotEmpty) {
        _entries.add(ActivityLogEntry(
          type:       LogEntryType.user,
          actor:      user['name'] ?? 'Pekerja',
          timestamp:  _fmt(createdAt),
          date:       _parse(createdAt),
          body:       notes,
          avatarIcon: Icons.person,
        ));
      }

      if (issue != null) {
        _entries.add(ActivityLogEntry(
          type:       LogEntryType.alert,
          actor:      'Sistem Peringatan',
          timestamp:  _fmt(createdAt),
          date:       _parse(createdAt),
          alertTitle: 'Alarm Kritis: ${checkpoint['name'] ?? 'Checkpoint'}',
          body:       issue['description'] as String? ?? 'Kendala terdeteksi.',
        ));
      }
    }

    // Fallback: completed schedules if no reports
    if (_entries.isEmpty) {
      for (final s in schedules) {
        final sc         = s as Map<String, dynamic>;
        if ((sc['status'] as String?) != 'completed') continue;
        final checkpoint = sc['checkpoint']    as Map<String, dynamic>? ?? {};
        final category   = sc['task_category'] as Map<String, dynamic>? ?? {};
        final shiftDate  = sc['shift_date']    as String? ?? '';
        _entries.add(ActivityLogEntry(
          type:      LogEntryType.system,
          actor:     'Sistem BMS',
          timestamp: sc['scheduled_time'] as String? ?? '--:--',
          date:      _parse(shiftDate),
          body:      'Check-in selesai di ${checkpoint['name'] ?? '-'} — ${category['name'] ?? ''}',
          workOrder: 'SCH-${sc['id'] ?? '0'}',
          source:    'Diselesaikan via Mobile App',
        ));
      }
    }

    _entries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// Push a newly submitted report immediately (real-time update)
  void pushReport({
    required Map<String, dynamic> reportData,
    required Map<String, dynamic> schedule,
    required String               userName,
    required Uint8List?           photoBytes,
    required String               photoLocalPath,
    String?                       notes,
    String?                       issueDescription,
  }) {
    final now        = DateTime.now();
    final checkpoint = schedule['checkpoint'] as Map<String, dynamic>? ?? {};
    final category   = schedule['task_category'] as Map<String, dynamic>? ?? {};
    final ts         = _fmtNow(now);
    final reportId   = reportData['id']?.toString() ?? '????';

    // 1. System BMS — completion notice
    _entries.insert(0, ActivityLogEntry(
      type:      LogEntryType.system,
      actor:     'Sistem BMS',
      timestamp: ts,
      date:      now,
      body:      '$userName menyelesaikan tugas di ${checkpoint['name'] ?? 'Checkpoint'}'
                 ' (${category['name'] ?? '-'})',
      photoUrl:  photoLocalPath.isNotEmpty ? photoLocalPath : null,
      workOrder: 'WO-$reportId',
      source:    'Dikirim via Mobile App',
    ));

    // 2. Notes — user text bubble
    if (notes != null && notes.trim().isNotEmpty) {
      _entries.insert(0, ActivityLogEntry(
        type:       LogEntryType.user,
        actor:      userName,
        timestamp:  ts,
        date:       now,
        body:       notes.trim(),
        avatarIcon: Icons.engineering,
      ));
    }

    // 3. Issue — critical alert bubble
    if (issueDescription != null && issueDescription.trim().isNotEmpty) {
      _entries.insert(0, ActivityLogEntry(
        type:       LogEntryType.alert,
        actor:      'Sistem Peringatan',
        timestamp:  ts,
        date:       now,
        alertTitle: 'Kendala: ${checkpoint['name'] ?? 'Checkpoint'}',
        body:       issueDescription.trim(),
      ));
    }

    notifyListeners();
  }

  /// Push a plain chat message typed by the user
  void pushChatMessage({required String actor, required String body}) {
    final now = DateTime.now();
    _entries.insert(0, ActivityLogEntry(
      type:       LogEntryType.user,
      actor:      actor,
      timestamp:  _fmtNow(now),
      date:       now,
      body:       body,
      avatarIcon: Icons.person,
    ));
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _fmt(String iso) {
    try {
      final dt  = DateTime.parse(iso).toLocal();
      final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m   = dt.minute.toString().padLeft(2, '0');
      final p   = dt.hour < 12 ? 'AM' : 'PM';
      return '${h12.toString().padLeft(2, '0')}:$m $p';
    } catch (_) { return ''; }
  }

  static String _fmtNow(DateTime dt) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m   = dt.minute.toString().padLeft(2, '0');
    final p   = dt.hour < 12 ? 'AM' : 'PM';
    return '${h12.toString().padLeft(2, '0')}:$m $p';
  }

  static DateTime _parse(String iso) {
    try { return DateTime.parse(iso).toLocal(); }
    catch (_) { return DateTime.now(); }
  }
}

// needed for Uint8List without importing dart:typed_data everywhere
