import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'app_config.dart';

/// Crash Reporting Service
/// 
/// Simple crash reporting that logs errors to file and can be sent to server
/// For production, consider using Firebase Crashlytics or Sentry
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  bool _initialized = false;
  File? _logFile;

  /// Initialize crash reporting
  Future<void> initialize() async {
    if (_initialized || !AppConfig.enableCrashReporting) return;

    try {
      // Setup log file
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/crash_logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName = 'crash_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.log';
      _logFile = File('${logDir.path}/$fileName');

      // Capture Flutter errors
      FlutterError.onError = (FlutterErrorDetails details) {
        _logError(
          error: details.exception,
          stackTrace: details.stack,
          context: details.context?.toString(),
          library: details.library,
        );
        
        // Still print to console in debug mode
        if (AppConfig.isDebug) {
          FlutterError.dumpErrorToConsole(details);
        }
      };

      // Capture async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        _logError(error: error, stackTrace: stack);
        return true;
      };

      _initialized = true;
      await _logEvent('CrashReportingService initialized');
    } catch (e) {
      debugPrint('Failed to initialize crash reporting: $e');
    }
  }

  /// Log an error
  Future<void> _logError({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    String? library,
  }) async {
    if (_logFile == null) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final buffer = StringBuffer();
      
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln('CRASH REPORT - $timestamp');
      buffer.writeln('───────────────────────────────────────────────────────────');
      buffer.writeln('Environment: ${AppConfig.environmentName}');
      buffer.writeln('App Version: ${AppConfig.appVersion}');
      if (library != null) buffer.writeln('Library: $library');
      if (context != null) buffer.writeln('Context: $context');
      buffer.writeln('───────────────────────────────────────────────────────────');
      buffer.writeln('ERROR:');
      buffer.writeln(error.toString());
      
      if (stackTrace != null) {
        buffer.writeln('───────────────────────────────────────────────────────────');
        buffer.writeln('STACK TRACE:');
        buffer.writeln(stackTrace.toString());
      }
      
      buffer.writeln('═══════════════════════════════════════════════════════════');
      buffer.writeln();

      await _logFile!.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );

      // In production, send to server here
      if (!AppConfig.isDebug) {
        // TODO: Send crash report to backend
        // await _sendToServer(buffer.toString());
      }
    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  /// Log a general event
  Future<void> _logEvent(String message) async {
    if (_logFile == null || !AppConfig.isDebug) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      await _logFile!.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  /// Manually report an error
  Future<void> reportError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {
    await _logError(
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Get crash logs
  Future<List<File>> getCrashLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/crash_logs');
      
      if (!await logDir.exists()) {
        return [];
      }

      final files = await logDir.list().where((entity) {
        return entity is File && entity.path.endsWith('.log');
      }).cast<File>().toList();

      // Sort by date (newest first)
      files.sort((a, b) => b.path.compareTo(a.path));
      
      return files;
    } catch (e) {
      debugPrint('Failed to get crash logs: $e');
      return [];
    }
  }

  /// Clear old crash logs (keep last 7 days)
  Future<void> clearOldLogs() async {
    try {
      final logs = await getCrashLogs();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      for (final log in logs) {
        final stat = await log.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await log.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to clear old logs: $e');
    }
  }

  /// Get crash log content
  Future<String?> getLogContent(File logFile) async {
    try {
      return await logFile.readAsString();
    } catch (e) {
      debugPrint('Failed to read log file: $e');
      return null;
    }
  }
}
