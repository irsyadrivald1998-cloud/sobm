import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String keyToken = 'auth_token';
  static const String keyUser = 'auth_user';
  static const String keyBaseUrl = 'api_base_url';

  // Default fallbacks based on platform/environment
  static String get defaultBaseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://f816-114-10-95-0.ngrok-free.app/api',
      );

  // Get active API Base URL
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    // Added /v1 to base URL to match backend changes
    final baseUrl = prefs.getString(keyBaseUrl) ?? defaultBaseUrl;
    return '$baseUrl/v1';
  }

  // Save active API Base URL
  Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, url);
  }

  // Reset active API Base URL
  Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyBaseUrl);
  }

  // Save token and user details on login
  Future<void> saveAuthSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
    await prefs.setString(keyUser, jsonEncode(user));
  }

  // Load token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  // Load user info
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(keyUser);
    if (userStr != null) {
      try {
        return jsonDecode(userStr) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Clear auth session (logout)
  Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
    await prefs.remove(keyUser);
  }

  // POST /login
  Future<Map<String, dynamic>> login(String employeeId, String password) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'employee_id': employeeId,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (responseData['status'] == true) {
        final data = responseData['data'];
        final token = data['token'];
        final user = data['user'];
        await saveAuthSession(token, user);
        return data;
      } else {
        throw Exception(responseData['message'] ?? 'Login gagal.');
      }
    } else {
      // Validation error or other server errors
      final msg = responseData['message'] ?? 'Login gagal (Error ${response.statusCode})';
      if (responseData['errors'] != null) {
        final errors = responseData['errors'] as Map<String, dynamic>;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first);
        }
      }
      throw Exception(msg);
    }
  }

  // POST /logout
  Future<void> logout() async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();
    if (token == null) {
      await clearAuthSession();
      return;
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Proceed with clearing session even if API logout fails
    } finally {
      await clearAuthSession();
    }
  }

  // GET /schedules
  Future<List<dynamic>> getSchedules() async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();
    if (token == null) throw Exception('Tidak terautentikasi.');

    final response = await http.get(
      Uri.parse('$baseUrl/schedules'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (responseData['status'] == true) {
        return responseData['data']['schedules'] as List<dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Gagal mengambil jadwal.');
      }
    } else {
      throw Exception(responseData['message'] ?? 'Error ${response.statusCode}');
    }
  }

  // GET /attendance/today
  Future<Map<String, dynamic>?> getTodayAttendance() async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();
    if (token == null) throw Exception('Tidak terautentikasi.');

    final response = await http.get(
      Uri.parse('$baseUrl/attendance/today'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData['status'] == true) {
      final data = responseData['data'];
      return data is Map ? Map<String, dynamic>.from(data) : null;
    }
    throw Exception(responseData['message'] ?? 'Gagal mengambil status absensi.');
  }

  Future<Map<String, dynamic>> _submitAttendance({
    required String action,
    required double latitude,
    required double longitude,
    required Uint8List photoBytes,
    required String photoName,
    String? notes,
  }) async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();
    if (token == null) throw Exception('Tidak terautentikasi.');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/attendance/$action'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    if (notes != null && notes.trim().isNotEmpty) {
      request.fields['notes'] = notes.trim();
    }
    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      photoBytes,
      filename: photoName,
    ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        responseData['status'] == true) {
      return Map<String, dynamic>.from(responseData['data'] as Map);
    }
    throw Exception(responseData['message'] ?? 'Gagal mengirim absensi.');
  }

  Future<Map<String, dynamic>> clockIn({
    required double latitude,
    required double longitude,
    required Uint8List photoBytes,
    required String photoName,
    String? notes,
  }) => _submitAttendance(
        action: 'clock-in',
        latitude: latitude,
        longitude: longitude,
        photoBytes: photoBytes,
        photoName: photoName,
        notes: notes,
      );

  Future<Map<String, dynamic>> clockOut({
    required double latitude,
    required double longitude,
    required Uint8List photoBytes,
    required String photoName,
  }) => _submitAttendance(
        action: 'clock-out',
        latitude: latitude,
        longitude: longitude,
        photoBytes: photoBytes,
        photoName: photoName,
      );

  // GET /reports — activity log with pagination
  Future<Map<String, dynamic>> getReports({int page = 1}) async {
    final baseUrl = await getBaseUrl();
    final token   = await getToken();
    if (token == null) throw Exception('Tidak terautentikasi.');

    final response = await http.get(
      Uri.parse('$baseUrl/reports?page=$page'),
      headers: {
        'Accept':        'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (responseData['status'] == true) {
        return responseData['data']['reports'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Gagal mengambil laporan.');
      }
    } else {
      throw Exception(responseData['message'] ?? 'Error ${response.statusCode}');
    }
  }

  // POST /reports (Multipart)
  Future<Map<String, dynamic>> submitReport({
    required int scheduleId,
    required double latitude,
    required double longitude,
    required String conditionStatus,
    String workDescription = '',
    String? notes,
    String? issueDescription,
    required Uint8List photoBytes,
    required String photoName,
  }) async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();
    if (token == null) throw Exception('Tidak terautentikasi.');

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/reports'));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['schedule_id'] = scheduleId.toString();
    request.fields['check_in_latitude'] = latitude.toString();
    request.fields['check_in_longitude'] = longitude.toString();
    request.fields['condition_status'] = conditionStatus;
    request.fields['work_description'] = workDescription;
    if (notes != null && notes.isNotEmpty) {
      request.fields['notes'] = notes;
    }
    if (conditionStatus == 'Ada Kendala' && issueDescription != null && issueDescription.isNotEmpty) {
      request.fields['issue_description'] = issueDescription;
    }

    final multipartFile = http.MultipartFile.fromBytes(
      'photo',
      photoBytes,
      filename: photoName,
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (responseData['status'] == true) {
        return responseData['data'] as Map<String, dynamic>;
      } else {
        throw Exception(responseData['message'] ?? 'Gagal mengirim laporan.');
      }
    } else {
      throw Exception(responseData['message'] ?? 'Gagal mengirim laporan (Error ${response.statusCode}).');
    }
  }
}
