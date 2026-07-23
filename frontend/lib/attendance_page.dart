import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'app_theme.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _attendanceStatus;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceStatus();
  }

  Future<void> _fetchAttendanceStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final status = await _apiService.getTodayAttendance();
      setState(() {
        _attendanceStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showAttendanceDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => _AttendanceDialog(
        action: action,
        apiService: _apiService,
        onSuccess: _fetchAttendanceStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool alreadyClockedIn = _attendanceStatus?['clock_in'] != null;
    final bool alreadyClockedOut = _attendanceStatus?['clock_out'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Absensi Hari Ini', style: AppTheme.titleLg),
        backgroundColor: AppTheme.surfaceLowest,
      ),
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: _fetchAttendanceStatus,
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spMd),
                    children: [
                      _buildStatusCard(alreadyClockedIn, alreadyClockedOut),
                      const SizedBox(height: AppTheme.spMd),
                      if (!alreadyClockedIn)
                        _buildActionButton(
                          'Clock In',
                          Icons.login,
                          AppTheme.primaryBrand,
                          () => _showAttendanceDialog('clock-in'),
                        ),
                      if (alreadyClockedIn && !alreadyClockedOut)
                        _buildActionButton(
                          'Clock Out',
                          Icons.logout,
                          AppTheme.alertCritical,
                          () => _showAttendanceDialog('clock-out'),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard(bool clockedIn, bool clockedOut) {
    final statusText = _attendanceStatus?['status'] ?? 'Belum Absen';
    final clockInTime = _attendanceStatus?['clock_in'] != null
        ? _formatTime(_attendanceStatus!['clock_in'])
        : '--:--';
    final clockOutTime = _attendanceStatus?['clock_out'] != null
        ? _formatTime(_attendanceStatus!['clock_out'])
        : '--:--';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spLg),
        child: Column(
          children: [
            Text(statusText, style: AppTheme.headlineSm),
            const SizedBox(height: AppTheme.spLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo('Clock In', clockInTime),
                _buildTimeInfo('Clock Out', clockOutTime),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelMd),
        Text(time, style: AppTheme.titleLg),
      ],
    );
  }

  String _formatTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }
}

class _AttendanceDialog extends StatefulWidget {
  final String action;
  final ApiService apiService;
  final VoidCallback onSuccess;

  const _AttendanceDialog({
    required this.action,
    required this.apiService,
    required this.onSuccess,
  });

  @override
  _AttendanceDialogState createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<_AttendanceDialog> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final position = await _determinePosition();
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) {
        setState(() => _isSubmitting = false);
        return;
      }
      final imageBytes = await image.readAsBytes();

      if (widget.action == 'clock-in') {
        await widget.apiService.clockIn(
          latitude: position.latitude,
          longitude: position.longitude,
          photoBytes: imageBytes,
          photoName: image.name,
        );
      } else {
        await widget.apiService.clockOut(
          latitude: position.latitude,
          longitude: position.longitude,
          photoBytes: imageBytes,
          photoName: image.name,
        );
      }
      widget.onSuccess();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Konfirmasi ${widget.action == 'clock-in' ? 'Clock In' : 'Clock Out'}'),
      content: const Text('Aplikasi akan mengambil foto dan lokasi Anda.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Lanjutkan'),
        ),
      ],
    );
  }
}
