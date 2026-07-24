import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

enum QueueItemType { attendance, report }
enum QueueItemStatus { pending, syncing, failed, completed }

class OfflineQueueManager {
  static Database? _database;
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();
  
  factory OfflineQueueManager() => _instance;
  
  OfflineQueueManager._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'offline_queue.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE queue_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            status TEXT NOT NULL,
            payload TEXT NOT NULL,
            photo_base64 TEXT,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
  }

  // Add item to queue
  Future<int> addToQueue({
    required QueueItemType type,
    required Map<String, dynamic> payload,
    Uint8List? photoBytes,
  }) async {
    final db = await database;
    
    return await db.insert('queue_items', {
      'type': type.name,
      'status': QueueItemStatus.pending.name,
      'payload': jsonEncode(payload),
      'photo_base64': photoBytes != null ? base64Encode(photoBytes) : null,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  // Get pending items
  Future<List<Map<String, dynamic>>> getPendingItems() async {
    final db = await database;
    return await db.query(
      'queue_items',
      where: 'status = ?',
      whereArgs: [QueueItemStatus.pending.name],
      orderBy: 'created_at ASC',
    );
  }

  // Get all items (for display)
  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await database;
    return await db.query(
      'queue_items',
      orderBy: 'created_at DESC',
      limit: 50,
    );
  }

  // Update item status
  Future<void> updateItemStatus(
    int id,
    QueueItemStatus status, {
    String? error,
  }) async {
    final db = await database;
    
    await db.update(
      'queue_items',
      {
        'status': status.name,
        'last_error': error,
        if (status == QueueItemStatus.failed) 
          'retry_count': await _getRetryCount(id) + 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> _getRetryCount(int id) async {
    final db = await database;
    final result = await db.query(
      'queue_items',
      columns: ['retry_count'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? (result.first['retry_count'] as int?) ?? 0 : 0;
  }

  // Delete completed items older than 7 days
  Future<void> cleanupOldItems() async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    
    await db.delete(
      'queue_items',
      where: 'status = ? AND created_at < ?',
      whereArgs: [
        QueueItemStatus.completed.name,
        cutoffDate.toIso8601String(),
      ],
    );
  }

  // Delete specific item
  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete(
      'queue_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync pending items when online
  Future<SyncResult> syncPendingItems() async {
    final apiService = ApiService();
    final pendingItems = await getPendingItems();
    
    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    for (final item in pendingItems) {
      final id = item['id'] as int;
      final type = item['type'] as String;
      final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
      final photoBase64 = item['photo_base64'] as String?;
      
      try {
        await updateItemStatus(id, QueueItemStatus.syncing);

        if (type == QueueItemType.attendance.name) {
          await _syncAttendance(apiService, payload, photoBase64);
        } else if (type == QueueItemType.report.name) {
          await _syncReport(apiService, payload, photoBase64);
        }

        await updateItemStatus(id, QueueItemStatus.completed);
        successCount++;
      } catch (e) {
        await updateItemStatus(id, QueueItemStatus.failed, error: e.toString());
        failureCount++;
        errors.add('Item #$id: ${e.toString()}');
      }
    }

    // Cleanup old completed items
    await cleanupOldItems();

    return SyncResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
    );
  }

  Future<void> _syncAttendance(
    ApiService apiService,
    Map<String, dynamic> payload,
    String? photoBase64,
  ) async {
    final action = payload['action'] as String;
    final latitude = payload['latitude'] as double;
    final longitude = payload['longitude'] as double;
    final photoBytes = photoBase64 != null ? base64Decode(photoBase64) : Uint8List(0);
    final photoName = payload['photo_name'] as String;
    final notes = payload['notes'] as String?;

    if (action == 'clock-in') {
      await apiService.clockIn(
        latitude: latitude,
        longitude: longitude,
        photoBytes: photoBytes,
        photoName: photoName,
        notes: notes,
      );
    } else if (action == 'clock-out') {
      await apiService.clockOut(
        latitude: latitude,
        longitude: longitude,
        photoBytes: photoBytes,
        photoName: photoName,
      );
    }
  }

  Future<void> _syncReport(
    ApiService apiService,
    Map<String, dynamic> payload,
    String? photoBase64,
  ) async {
    final photoBytes = photoBase64 != null ? base64Decode(photoBase64) : Uint8List(0);

    await apiService.submitReport(
      scheduleId: payload['schedule_id'] as int,
      latitude: payload['latitude'] as double,
      longitude: payload['longitude'] as double,
      conditionStatus: payload['condition_status'] as String,
      workDescription: payload['work_description'] as String? ?? '',
      notes: payload['notes'] as String?,
      issueDescription: payload['issue_description'] as String?,
      photoBytes: photoBytes,
      photoName: payload['photo_name'] as String,
    );
  }

  // Check if online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
           connectivityResult.contains(ConnectivityResult.wifi) ||
           connectivityResult.contains(ConnectivityResult.ethernet);
  }

  // Get pending count
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM queue_items WHERE status = ?',
      [QueueItemStatus.pending.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

class SyncResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;

  SyncResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });

  bool get hasErrors => failureCount > 0;
  bool get isSuccess => successCount > 0 && failureCount == 0;
}
