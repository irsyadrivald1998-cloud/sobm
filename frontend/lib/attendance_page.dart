import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _todayAttendance;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final attendance = await _apiService.getTodayAttendance();
      if (mounted) {
        setState(() {
          _todayAttendance = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusLabel(String? status) {
    return switch (status) {
      'hadir' => 'Hadir',
      'terlambat' => 'Terlambat',
      'alpa' => 'Alpa',
      'cuti' => 'Cuti',
      'izin' => 'Izin',
      'sakit' => 'Sakit',
      _ => 'Belum Absen',
    };
  }

  Color _getStatusColor(String? status) {
    return switch (status) {
      'hadir' => AppTheme.statusOk,
      'terlambat' => AppTheme.statusWarning,
      'alpa' => AppTheme.alertCritical,
      'cuti' => AppTheme.tertiary,
      'izin' => AppTheme.secondary,
      'sakit' => AppTheme.statusWarning,
      _ => AppTheme.outline,
    };
  }

  IconData _getStatusIcon(String? status) {
    return switch (status) {
      'hadir' => Icons.check_circle,
      'terlambat' => Icons.schedule,
      'alpa' => Icons.cancel,
      'cuti' => Icons.beach_access,
      'izin' => Icons.event_note,
      'sakit' => Icons.local_hospital,
      _ => Icons.pending,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Status Kehadiran', style: AppTheme.titleLg),
        backgroundColor: AppTheme.surfaceLowest,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendance,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
          : _errorMessage.isNotEmpty
              ? _buildError()
              : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/leave-submission').then((result) {
            if (result == true) _loadAttendance();
          });
        },
        backgroundColor: AppTheme.primaryBrand,
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Cuti/Izin'),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.alertCritical),
            const SizedBox(height: AppTheme.spMd),
            Text(_errorMessage, style: AppTheme.bodyLg, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spLg),
            ElevatedButton.icon(
              onPressed: _loadAttendance,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final status = _todayAttendance?['status'] as String?;
    final clockInTime = _todayAttendance?['clock_in_time'] as String?;
    final clockOutTime = _todayAttendance?['clock_out_time'] as String?;
    final notes = _todayAttendance?['notes'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.all(AppTheme.spLg),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: _getStatusColor(status).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 64,
                  color: _getStatusColor(status),
                ),
                const SizedBox(height: AppTheme.spMd),
                Text(
                  'Status Hari Ini',
                  style: AppTheme.bodyMd,
                ),
                const SizedBox(height: AppTheme.spXs),
                Text(
                  _getStatusLabel(status),
                  style: AppTheme.headlineMd.copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spLg),

          // Clock In/Out Times
          if (clockInTime != null || clockOutTime != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spMd),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
              ),
              child: Column(
                children: [
                  if (clockInTime != null)
                    _TimeRow(
                      icon: Icons.login,
                      label: 'Clock In',
                      time: _formatTime(clockInTime),
                    ),
                  if (clockInTime != null && clockOutTime != null)
                    const Divider(height: AppTheme.spMd),
                  if (clockOutTime != null)
                    _TimeRow(
                      icon: Icons.logout,
                      label: 'Clock Out',
                      time: _formatTime(clockOutTime),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spLg),
          ],

          // Notes
          if (notes != null && notes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spMd),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note_outlined, size: 20),
                      const SizedBox(width: AppTheme.spXs),
                      Text(
                        'Catatan',
                        style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spSm),
                  Text(notes, style: AppTheme.bodyMd),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spLg),
          ],

          // Status Legend
          Text(
            'Keterangan Status',
            style: AppTheme.headlineSm,
          ),
          const SizedBox(height: AppTheme.spMd),
          _StatusLegendItem(
            icon: Icons.check_circle,
            color: AppTheme.statusOk,
            label: 'Hadir',
            description: 'Absensi tepat waktu',
          ),
          const SizedBox(height: AppTheme.spSm),
          _StatusLegendItem(
            icon: Icons.schedule,
            color: AppTheme.statusWarning,
            label: 'Terlambat',
            description: 'Absensi setelah jam kerja dimulai',
          ),
          const SizedBox(height: AppTheme.spSm),
          _StatusLegendItem(
            icon: Icons.cancel,
            color: AppTheme.alertCritical,
            label: 'Alpa',
            description: 'Tidak melakukan absensi',
          ),
          const SizedBox(height: AppTheme.spSm),
          _StatusLegendItem(
            icon: Icons.beach_access,
            color: AppTheme.tertiary,
            label: 'Cuti',
            description: 'Pengajuan cuti yang disetujui',
          ),
          const SizedBox(height: AppTheme.spSm),
          _StatusLegendItem(
            icon: Icons.event_note,
            color: AppTheme.secondary,
            label: 'Izin',
            description: 'Pengajuan izin yang disetujui',
          ),
          const SizedBox(height: AppTheme.spSm),
          _StatusLegendItem(
            icon: Icons.local_hospital,
            color: AppTheme.statusWarning,
            label: 'Sakit',
            description: 'Pengajuan sakit dengan surat dokter',
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (_) {
      return time;
    }
  }
}

class _TimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;

  const _TimeRow({
    required this.icon,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppTheme.primaryBrand),
        const SizedBox(width: AppTheme.spMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.labelMd),
              const SizedBox(height: 2),
              Text(
                time,
                style: AppTheme.bodyLg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusLegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String description;

  const _StatusLegendItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
  });

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
          Container(
            padding: const EdgeInsets.all(AppTheme.spSm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppTheme.spMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(description, style: AppTheme.labelMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
