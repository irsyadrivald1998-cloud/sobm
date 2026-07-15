import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isLoggedIn = await _apiService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
        return;
      }

      final userData = await _apiService.getUser();
      final schedulesData = await _apiService.getSchedules();

      setState(() {
        _user = userData;
        _schedules = schedulesData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1F),
        title: const Text('Keluar Aplikasi', style: TextStyle(color: Colors.white)),
        content: const Text('Apakah Anda yakin ingin keluar?', style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _apiService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD13639)),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatIndonesianDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final dayName = days[date.weekday % 7];
      final monthName = months[date.month - 1];
      return '$dayName, ${date.day} $monthName ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  bool _isScheduleToday(String shiftDateStr) {
    try {
      final shiftDate = DateTime.parse(shiftDateStr);
      final now = DateTime.now();
      return shiftDate.year == now.year && shiftDate.month == now.month && shiftDate.day == now.day;
    } catch (_) {
      return false;
    }
  }

  void _openCheckInDialog(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CheckInDialog(
          schedule: schedule,
          apiService: _apiService,
          onSuccess: () {
            _loadInitialData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _schedules.where((s) => s['status'] == 'pending').length;
    final completedCount = _schedules.where((s) => s['status'] == 'completed').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E12),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Color(0xFFD13639), size: 28),
            const SizedBox(width: 10),
            const Text(
              'SOBM Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: const Color(0xFFD13639),
        backgroundColor: const Color(0xFF1C1C1F),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFD13639)),
              )
            : _errorMessage.isNotEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Center.alignment,
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFD13639), size: 60),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadInitialData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD13639),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // Profile Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A1F2E), Color(0xFF0F1419)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF2C2C2F)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFFD13639).withOpacity(0.2),
                                  child: const Icon(Icons.person, color: Color(0xFFD13639), size: 30),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _user?['name'] ?? 'Pekerja',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Role: ${(_user?['role'] ?? '-').toString().toUpperCase()}',
                                        style: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID Karyawan: ${_user?['employee_id'] ?? '-'}',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Stats counters
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'TUGAS PENDING',
                                  pendingCount.toString(),
                                  const Color(0xFFFBBF24),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'SELESAI',
                                  completedCount.toString(),
                                  const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Section Title
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 28.0, bottom: 12.0),
                          child: Text(
                            'DAFTAR JADWAL TUGAS',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      // Schedules List
                      _schedules.isEmpty
                          ? SliverToBoxAdapter(
                              child: Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Tidak ada jadwal tugas ditemukan.',
                                  style: TextStyle(color: Color(0xFF9CA3AF)),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final schedule = _schedules[index];
                                    final checkpoint = schedule['checkpoint'] ?? {};
                                    final category = schedule['task_category'] ?? {};
                                    final shiftDate = schedule['shift_date'] ?? '';
                                    final time = schedule['scheduled_time'] ?? '';
                                    final status = schedule['status'] ?? 'pending';

                                    final isToday = _isScheduleToday(shiftDate);
                                    final isPending = status == 'pending';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1C1C1F),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF2C2C2F)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Checkpoint and Status
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.between,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    checkpoint['name'] ?? 'Checkpoint Tanpa Nama',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isPending
                                                        ? const Color(0xFFFBBF24).withOpacity(0.2)
                                                        : const Color(0xFF10B981).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isPending ? 'PENDING' : 'SELESAI',
                                                    style: TextStyle(
                                                      color: isPending
                                                          ? const Color(0xFFFBBF24)
                                                          : const Color(0xFF10B981),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Details
                                            Row(
                                              children: [
                                                const Icon(Icons.category_outlined, color: Color(0xFF9CA3AF), size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Tugas: ${category['name'] ?? '-'}',
                                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_month_outlined, color: Color(0xFF9CA3AF), size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatIndonesianDate(shiftDate),
                                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time, color: Color(0xFF9CA3AF), size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Jam: $time WIB',
                                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                                ),
                                              ],
                                            ),

                                            // Action Button
                                            if (isPending) ...[
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 40,
                                                child: ElevatedButton(
                                                  onPressed: isToday ? () => _openCheckInDialog(schedule) : null,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFD13639),
                                                    foregroundColor: Colors.white,
                                                    disabledBackgroundColor: const Color(0xFF2C2C2F),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.location_on_outlined, size: 18),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        isToday
                                                            ? 'Check In Sekarang'
                                                            : 'Check In Hanya Pada Hari H',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: isToday ? Colors.white : const Color(0xFF6B7280),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: _schedules.length,
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckInDialog extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final ApiService apiService;
  final VoidCallback onSuccess;

  const CheckInDialog({
    super.key,
    required this.schedule,
    required this.apiService,
    required this.onSuccess,
  });

  @override
  State<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<CheckInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _issueController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isGettingLocation = false;
  Position? _currentPosition;
  double? _distance;

  bool _isCapturingPhoto = false;
  XFile? _photoFile;
  Uint8List? _photoBytes;

  String _conditionStatus = 'Aman/Bersih';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000; // Earth's radius in meters
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
      _distance = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi dinonaktifkan. Silakan aktifkan GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin akses lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen di pengaturan.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final checkpoint = widget.schedule['checkpoint'] ?? {};
      final double cpLat = double.parse(checkpoint['latitude'].toString());
      final double cpLng = double.parse(checkpoint['longitude'].toString());

      final distance = _calculateDistance(position.latitude, position.longitude, cpLat, cpLng);

      setState(() {
        _currentPosition = position;
        _distance = distance;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFD13639),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isCapturingPhoto = true;
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _photoFile = photo;
          _photoBytes = bytes;
          _isCapturingPhoto = false;
        });
      } else {
        setState(() {
          _isCapturingPhoto = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCapturingPhoto = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: const Color(0xFFD13639),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan dapatkan GPS koordinat terlebih dahulu.'),
          backgroundColor: Color(0xFFD13639),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_photoBytes == null || _photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan ambil foto tugas terlebih dahulu.'),
          backgroundColor: Color(0xFFD13639),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final checkpoint = widget.schedule['checkpoint'] ?? {};
    final int radius = int.parse(checkpoint['radius_meter'].toString());

    if (_distance != null && _distance! > radius) {
      final over = (_distance! - radius).ceil();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: Anda berada $over meter di luar jangkauan lokasi tugas!'),
          backgroundColor: const Color(0xFFD13639),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.apiService.submitReport(
        scheduleId: widget.schedule['id'],
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        conditionStatus: _conditionStatus,
        notes: _notesController.text.trim(),
        issueDescription: _conditionStatus == 'Ada Kendala' ? _issueController.text.trim() : null,
        photoBytes: _photoBytes!,
        photoName: _photoFile!.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dikirim!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFD13639),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkpoint = widget.schedule['checkpoint'] ?? {};
    final int radius = int.parse(checkpoint['radius_meter'].toString());

    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1F),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          const Text(
            'Form Check In Tugas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkpoint info header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2C2C2F)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkpoint['name'] ?? 'Checkpoint',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Target Koordinat: ${checkpoint['latitude']}, ${checkpoint['longitude']}',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                      ),
                      Text(
                        'Radius Toleransi: $radius meter',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // GPS Location Section
                const Text(
                  '1. VALIDASI LOKASI GPS (WAJIB)',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isGettingLocation ? null : _getLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: _isGettingLocation
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.gps_fixed, size: 16),
                                  SizedBox(width: 8),
                                  Text('Dapatkan GPS'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi Anda: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        if (_distance != null) ...[
                          Row(
                            children: [
                              Text(
                                'Jarak ke Target: ${_distance!.toStringAsFixed(1)} meter ',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              Icon(
                                _distance! <= radius ? Icons.check_circle : Icons.warning,
                                size: 16,
                                color: _distance! <= radius ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_distance! > radius)
                            Text(
                              'Peringatan: Anda berada ${(_distance! - radius).ceil()}m di luar jangkauan!',
                              style: const TextStyle(color: Color(0xFFD13639), fontSize: 12, fontWeight: FontWeight.bold),
                            )
                          else
                            const Text(
                              'Lokasi valid untuk check-in.',
                              style: TextStyle(color: Colors.green, fontSize: 12),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Photo Capture Section
                const Text(
                  '2. FOTO TUGAS (WAJIB)',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isCapturingPhoto ? null : _takePhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: _isCapturingPhoto
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Ambil Foto Kamera'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                if (_photoBytes != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF2C2C2F)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        _photoBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Condition Status Section
                const Text(
                  '3. STATUS KONDISI',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _conditionStatus,
                  dropdownColor: const Color(0xFF1C1C1F),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0A0E12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Aman/Bersih',
                      child: Text('Aman / Bersih'),
                    ),
                    DropdownMenuItem(
                      value: 'Ada Kendala',
                      child: Text('Ada Kendala'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _conditionStatus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Notes (Optional)
                const Text(
                  '4. CATATAN TAMBAHAN (OPSIONAL)',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ketik catatan di sini...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF0A0E12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),

                // Issue Description (Only if Ada Kendala)
                if (_conditionStatus == 'Ada Kendala') ...[
                  const Text(
                    '5. DESKRIPSI KENDALA (WAJIB)',
                    style: TextStyle(color: Color(0xFFD13639), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _issueController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Deskripsikan kendala yang terjadi secara detail...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF0A0E12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFD13639), width: 1),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (value) {
                      if (_conditionStatus == 'Ada Kendala' && (value == null || value.trim().isEmpty)) {
                        return 'Deskripsi kendala wajib diisi jika ada kendala.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD13639),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF7A1F21),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Kirim Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
