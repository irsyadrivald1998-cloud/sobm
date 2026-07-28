import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'api_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  Timer? _liveTimer;
  DateTime _now = DateTime.now();

  // ── Today tab state ──────────────────────────────────────────────────────
  Map<String, dynamic>? _todayAttendance;
  bool _isLoadingToday = true;
  String _errorToday = '';
  bool _isSubmitting = false;

  // ── History tab state ────────────────────────────────────────────────────
  List<dynamic> _historyList = [];
  bool _isLoadingHistory = false;
  String _errorHistory = '';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _historyList.isEmpty && !_isLoadingHistory) {
        _loadHistory();
      }
    });
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _loadToday();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadToday() async {
    setState(() { _isLoadingToday = true; _errorToday = ''; });
    try {
      final data = await _apiService.getTodayAttendance();
      if (mounted) setState(() { _todayAttendance = data; _isLoadingToday = false; });
    } catch (e) {
      if (mounted) setState(() { _errorToday = e.toString().replaceAll('Exception: ', ''); _isLoadingToday = false; });
    }
  }

  Future<void> _loadHistory() async {
    setState(() { _isLoadingHistory = true; _errorHistory = ''; });
    try {
      final data = await _apiService.getAttendanceHistory(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) {
        setState(() {
          _historyList = (data['attendances'] as List<dynamic>?) ?? [];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorHistory = e.toString().replaceAll('Exception: ', ''); _isLoadingHistory = false; });
    }
  }

  // ── Clock In / Out flow ──────────────────────────────────────────────────

  Future<void> _startClockFlow(bool isClockIn) async {
    setState(() => _isSubmitting = true);
    try {
      // For clock-in, check time window first before proceeding
      if (isClockIn) {
        await _checkClockInWindow();
      }

      // 1. Get GPS
      final position = await _getLocation();
      if (position == null) { setState(() => _isSubmitting = false); return; }

      // 2. Take selfie
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );
      if (photo == null) { setState(() => _isSubmitting = false); return; }

      // 3. Confirmation dialog
      if (!mounted) { setState(() => _isSubmitting = false); return; }
      final confirmed = await _showConfirmDialog(
        isClockIn: isClockIn,
        photo: photo,
        position: position,
      );
      if (!confirmed) { setState(() => _isSubmitting = false); return; }

      // 4. Submit
      final photoBytes = await photo.readAsBytes();
      final photoName  = isClockIn ? 'clock_in_${DateTime.now().millisecondsSinceEpoch}.jpg'
                                   : 'clock_out_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (isClockIn) {
        await _apiService.clockIn(
          latitude: position.latitude,
          longitude: position.longitude,
          photoBytes: photoBytes,
          photoName: photoName,
        );
      } else {
        await _apiService.clockOut(
          latitude: position.latitude,
          longitude: position.longitude,
          photoBytes: photoBytes,
          photoName: photoName,
        );
      }

      if (mounted) {
        _showSnack(isClockIn ? 'Absen masuk berhasil!' : 'Absen keluar berhasil!',
            isError: false);
        await _loadToday();
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _checkClockInWindow() async {
    try {
      // Get today's attendance to check if schedule exists
      final data = await _apiService.getTodayAttendance();
      
      // If attendance already exists with clock-in, no need to check window
      if (data != null && data['clock_in_time'] != null) {
        return;
      }
      
      // The API will handle time validation, but we can show a warning
      // if it's too early based on typical shift times
      final now = DateTime.now();
      final hour = now.hour;
      
      // Typical shift start is 08:00, so warn if before 07:30
      if (hour < 7 || (hour == 7 && now.minute < 30)) {
        if (mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Waktu Absen Terlalu Awal'),
              content: const Text(
                'Anda mencoba absen lebih dari 30 menit sebelum jam kerja dimulai. '
                'Absen dibuka 30 menit sebelum jam kerja. Lanjutkan?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Lanjutkan'),
                ),
              ],
            ),
          );
          if (confirmed != true) {
            throw Exception('Absen dibatalkan oleh pengguna');
          }
        }
      }
    } catch (e) {
      // If there's any error checking, just proceed and let the API handle validation
      if (mounted && e.toString().contains('Absen dibatalkan')) {
        rethrow;
      }
    }
  }

  Future<Position?> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showSnack('Izin lokasi diperlukan untuk absensi.', isError: true);
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      if (mounted) _showSnack('Gagal mendapatkan lokasi: $e', isError: true);
      return null;
    }
  }

  Future<bool> _showConfirmDialog({
    required bool isClockIn,
    required XFile photo,
    required Position position,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClockConfirmSheet(
        isClockIn: isClockIn,
        photo: photo,
        position: position,
      ),
    );
    return result == true;
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.statusOk,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppTheme.spMd),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
    ));
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  String _statusLabel(String? s) => switch (s) {
        'Hadir' => 'Hadir',
        'Terlambat' => 'Terlambat',
        'Alpa' => 'Alpa',
        _ => 'Belum Absen',
      };

  Color _statusColor(String? s) => switch (s) {
        'Hadir' => AppTheme.statusOk,
        'Terlambat' => AppTheme.statusWarning,
        'Alpa' => AppTheme.alertCritical,
        _ => AppTheme.outline,
      };

  IconData _statusIcon(String? s) => switch (s) {
        'Hadir' => Icons.check_circle_rounded,
        'Terlambat' => Icons.schedule_rounded,
        'Alpa' => Icons.cancel_rounded,
        _ => Icons.fingerprint,
      };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Absensi', style: AppTheme.titleLg.copyWith(color: cs.onSurface)),
        backgroundColor: cs.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBrand,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: AppTheme.primaryBrand,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Hari Ini', icon: Icon(Icons.today_outlined, size: 18)),
            Tab(text: 'Riwayat', icon: Icon(Icons.calendar_month_outlined, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  TAB 1 — Hari Ini
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTodayTab() {
    if (_isLoadingToday) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand));
    }
    if (_errorToday.isNotEmpty) {
      return _buildError(_errorToday, _loadToday);
    }
    return _buildTodayContent();
  }

  Widget _buildTodayContent() {
    final status      = _todayAttendance?['status'] as String?;
    final clockInRaw  = _todayAttendance?['clock_in_time'] as String?;
    final clockOutRaw = _todayAttendance?['clock_out_time'] as String?;
    final notes       = _todayAttendance?['notes'] as String?;

    final hasClockIn  = clockInRaw != null;
    final hasClockOut = clockOutRaw != null;

    final today = '${_dayName(_now.weekday)}, ${_now.day} ${_monthName(_now.month)} ${_now.year}';
    final liveClockStr = '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final liveClockSecStr = '$liveClockStr:${_now.second.toString().padLeft(2, '0')}';

    return RefreshIndicator(
      onRefresh: _loadToday,
      color: AppTheme.primaryBrand,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Real-time HP Clock Header ─────────────────────────────────────
            Text(today, style: AppTheme.labelMd.copyWith(color: AppTheme.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_filled_rounded, color: AppTheme.statusOk, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$liveClockSecStr WIB',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spMd),

            // ── Big status card ──────────────────────────────────────────────
            _StatusCard(
              status: status,
              statusLabel: _statusLabel(status),
              statusColor: _statusColor(status),
              statusIcon: _statusIcon(status),
            ),
            const SizedBox(height: AppTheme.spLg),

            // ── Timeline clock-in / clock-out ─────────────────────────────────
            _TimelineCard(
              clockIn: hasClockIn ? _fmtTime(clockInRaw) : liveClockStr,
              clockOut: hasClockOut ? _fmtTime(clockOutRaw) : null,
              isClockInLive: !hasClockIn,
            ),
            const SizedBox(height: AppTheme.spLg),

            // ── Action buttons ───────────────────────────────────────────────
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
            else ...[
              if (!hasClockIn)
                _ActionButton(
                  label: 'Clock In',
                  icon: Icons.login_rounded,
                  color: AppTheme.statusOk,
                  onTap: () => _startClockFlow(true),
                ),
              if (hasClockIn && !hasClockOut)
                _ActionButton(
                  label: 'Clock Out',
                  icon: Icons.logout_rounded,
                  color: AppTheme.primaryBrand,
                  onTap: () => _startClockFlow(false),
                ),
              if (hasClockIn && hasClockOut)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spMd),
                  decoration: BoxDecoration(
                    color: AppTheme.statusOk.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.statusOk.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.statusOk, size: 20),
                      const SizedBox(width: AppTheme.spSm),
                      Text('Absensi hari ini selesai',
                          style: AppTheme.bodyMd.copyWith(color: AppTheme.statusOk, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],

            // ── Notes ──────────────────────────────────────────────────────
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spMd),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_outlined, size: 18, color: AppTheme.outline),
                    const SizedBox(width: AppTheme.spSm),
                    Expanded(child: Text(notes, style: AppTheme.bodyMd)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spLg),

            // ── Ajukan cuti / izin ──────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/leave-submission').then((result) {
                  if (result == true) _loadToday();
                });
              },
              icon: const Icon(Icons.event_note_outlined, size: 18),
              label: const Text('Ajukan Cuti / Izin'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryBrand),
                foregroundColor: AppTheme.primaryBrand,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  TAB 2 — Riwayat
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHistoryTab() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // ── Month picker ─────────────────────────────────────────────────────
        Container(
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spMd, vertical: AppTheme.spSm),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _changeMonth(-1),
                color: cs.onSurface,
              ),
              Expanded(
                child: Text(
                  '${_monthName(_selectedMonth)} $_selectedYear',
                  style: AppTheme.bodyLg.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _changeMonth(1),
                color: cs.onSurface,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant),
        // ── List ──────────────────────────────────────────────────────────
        Expanded(child: _buildHistoryList()),
      ],
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) { _selectedMonth = 1; _selectedYear++; }
      if (_selectedMonth < 1) { _selectedMonth = 12; _selectedYear--; }
      _historyList = [];
    });
    _loadHistory();
  }

  Widget _buildHistoryList() {
    final cs = Theme.of(context).colorScheme;
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand));
    }
    if (_errorHistory.isNotEmpty) {
      return _buildError(_errorHistory, _loadHistory);
    }
    if (_historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy_outlined, size: 56, color: AppTheme.outline),
            const SizedBox(height: AppTheme.spMd),
            Text('Tidak ada data absensi\npada bulan ini',
                style: AppTheme.bodyLg.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spMd),
      itemCount: _historyList.length,
      separatorBuilder: (context, idx) => const SizedBox(height: AppTheme.spSm),
      itemBuilder: (_, i) {
        final item = _historyList[i] as Map<String, dynamic>;
        final status    = item['status'] as String?;
        final dateStr   = item['date'] as String? ?? '';
        final clockIn   = item['clock_in_time'] as String?;
        final clockOut  = item['clock_out_time'] as String?;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
          ),
          padding: const EdgeInsets.all(AppTheme.spMd),
          child: Row(
            children: [
              // Date box
              Container(
                width: 48,
                height: 52,
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_dayFromDate(dateStr),
                        style: AppTheme.labelSm.copyWith(color: _statusColor(status))),
                    Text(_dateNum(dateStr),
                        style: AppTheme.bodyLg.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _statusColor(status))),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spMd),
              // Status + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_statusIcon(status), size: 16, color: _statusColor(status)),
                        const SizedBox(width: 4),
                        Text(_statusLabel(status),
                            style: AppTheme.bodyMd.copyWith(
                                fontWeight: FontWeight.w600, color: _statusColor(status))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (clockIn != null) ...[
                          const Icon(Icons.login, size: 13, color: AppTheme.outline),
                          const SizedBox(width: 3),
                          Text(_fmtTime(clockIn), style: AppTheme.labelMd),
                        ],
                        if (clockIn != null && clockOut != null) ...[
                          const SizedBox(width: AppTheme.spSm),
                          const Text('→', style: TextStyle(color: AppTheme.outline, fontSize: 12)),
                          const SizedBox(width: AppTheme.spSm),
                        ],
                        if (clockOut != null) ...[
                          const Icon(Icons.logout, size: 13, color: AppTheme.outline),
                          const SizedBox(width: 3),
                          Text(_fmtTime(clockOut), style: AppTheme.labelMd),
                        ],
                        if (clockIn == null && clockOut == null)
                          Text('—', style: AppTheme.labelMd),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Shared error widget ──────────────────────────────────────────────────

  Widget _buildError(String msg, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.alertCritical),
            const SizedBox(height: AppTheme.spMd),
            Text(msg, style: AppTheme.bodyLg, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spLg),
            ElevatedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date/time helpers ────────────────────────────────────────────────────

  String _fmtTime(String? raw) {
    if (raw == null) return '—';
    try {
      if (raw.contains('T') || raw.endsWith('Z')) {
        final dt = DateTime.parse(raw).toLocal();
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      final parts = raw.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String _dayName(int wd) {
    const d = ['','Sen','Sel','Rab','Kam','Jum','Sab','Min'];
    return d[wd % 7 == 0 ? 7 : wd % 7];
  }

  String _monthName(int m) {
    const months = ['','Januari','Februari','Maret','April','Mei','Juni',
        'Juli','Agustus','September','Oktober','November','Desember'];
    return m >= 1 && m <= 12 ? months[m] : '-';
  }

  String _dayFromDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const days = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];
      return days[d.weekday % 7];
    } catch (_) { return ''; }
  }

  String _dateNum(String dateStr) {
    try { return DateTime.parse(dateStr).day.toString(); } catch (_) { return '-'; }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _StatusCard extends StatelessWidget {
  final String? status;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;

  const _StatusCard({
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 44, color: statusColor),
          ),
          const SizedBox(height: AppTheme.spMd),
          Text('Status Hari Ini', style: AppTheme.labelMd.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: AppTheme.spXs),
          Text(
            statusLabel,
            style: AppTheme.headlineMd.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String? clockIn;
  final String? clockOut;
  final bool isClockInLive;

  const _TimelineCard({this.clockIn, this.clockOut, this.isClockInLive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: _TimeCell(
            icon: Icons.login_rounded,
            label: isClockInLive ? 'Clock In (Real-time)' : 'Clock In',
            time: clockIn ?? '—',
            color: isClockInLive ? AppTheme.statusOk : (clockIn != null ? AppTheme.statusOk : AppTheme.outline),
          )),
          Container(width: 1, height: 48, color: AppTheme.outlineVariant),
          Expanded(child: _TimeCell(
            icon: Icons.logout_rounded,
            label: 'Clock Out',
            time: clockOut ?? '—',
            color: clockOut != null ? AppTheme.primaryBrand : AppTheme.outline,
          )),
        ],
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeCell({required this.icon, required this.label, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(time, style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd + 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: AppTheme.spSm),
              Text(
                label,
                style: AppTheme.bodyLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirmation bottom sheet ─────────────────────────────────────────────────

class _ClockConfirmSheet extends StatelessWidget {
  final bool isClockIn;
  final XFile photo;
  final Position position;

  const _ClockConfirmSheet({
    required this.isClockIn,
    required this.photo,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppTheme.spMd),
            child: Column(
              children: [
                Text(
                  isClockIn ? 'Konfirmasi Clock In' : 'Konfirmasi Clock Out',
                  style: AppTheme.headlineSm,
                ),
                const SizedBox(height: AppTheme.spMd),

                // Photo preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: kIsWeb
                      ? Image.network(photo.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(File(photo.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: AppTheme.spMd),

                // Location info
                Container(
                  padding: const EdgeInsets.all(AppTheme.spSm),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primaryBrand),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                          style: AppTheme.labelMd,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spMd),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spMd),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isClockIn ? AppTheme.statusOk : AppTheme.primaryBrand,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(isClockIn ? 'Clock In' : 'Clock Out'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
