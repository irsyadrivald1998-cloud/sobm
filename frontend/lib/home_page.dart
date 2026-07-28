import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'main.dart' show ActivityLogProvider, NotificationProvider;
import 'task_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HomePage  (Dashboard)
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _user;
  List<dynamic> _schedules = [];
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedTab = 0;

  // ── Attendance state ──────────────────────────────────────────────────────
  Map<String, dynamic>? _todayAttendance;
  bool _attendanceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      if (!await _apiService.isLoggedIn()) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
        return;
      }
      final userData      = await _apiService.getUser();
      final schedulesData = await _apiService.getSchedules();
      Map<String, dynamic> reportsData = {'data': []};
      try {
        reportsData = await _apiService.getReports();
      } catch (_) {
        // Ignore reports error, use empty map with empty data array
      }

      // Load today's attendance (non-blocking)
      _apiService.getTodayAttendance().then((att) {
        if (mounted) setState(() { _todayAttendance = att; _attendanceLoaded = true; });
      }).catchError((_) {
        if (mounted) setState(() => _attendanceLoaded = true);
      });

      final reportsList = (reportsData['data'] as List<dynamic>?) ?? [];

      setState(() {
        _user      = userData;
        _schedules = schedulesData;
        _reports   = reportsList;
        _isLoading = false;
      });

      // Seed the shared activity log notifier
      if (mounted) {
        ActivityLogProvider.of(context)
          .seedFromApi(reportsData, schedulesData);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading    = false;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: Text('Apakah Anda yakin ingin keluar?', style: AppTheme.bodyMd),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              nav.pop();
              await _apiService.logout();
              nav.pushReplacementNamed('/');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _openCheckInDialog(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CheckInDialog(
        schedule: schedule,
        apiService: _apiService,
        userName: _user?['name'] ?? 'Pekerja',
        onSuccess: (reportData, photoBytes, photoPath) {
          _loadInitialData();
          // Real-time push to activity log
          ActivityLogProvider.of(context).pushReport(
            reportData:     reportData,
            schedule:       schedule,
            userName:       _user?['name'] ?? 'Pekerja',
            photoBytes:     photoBytes,
            photoLocalPath: photoPath,
            notes:          reportData['notes'] as String?,
            issueDescription: reportData['issue_description'] as String?,
          );
        },
      ),
    );
  }

  void _openTaskDetail({int initialIndex = 0}) {
    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada jadwal tugas hari ini.'),
      ));
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => TaskDetailPage(
            schedules:    _schedules,
            apiService:   _apiService,
            user:         _user,
            initialIndex: initialIndex,
          ),
        ))
        .then((refreshed) {
          if (refreshed == true) _loadInitialData();
        });
  }


  bool _isScheduleToday(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final n = DateTime.now();
      return d.year == n.year && d.month == n.month && d.day == n.day;
    } catch (_) { return false; }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days   = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
      return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) { return dateStr; }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use theme's scaffold background color for proper light/dark mode support
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
          : _errorMessage.isNotEmpty
              ? _buildError()
              : _buildDashboard(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Error State ───────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spXl),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppTheme.alertCritical, size: 56),
          const SizedBox(height: AppTheme.spMd),
          Text(_errorMessage, style: AppTheme.bodyLg, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spLg),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ]),
      ),
    );
  }

  // ── Dashboard Body ────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final pendingCount   = _schedules.where((s) => s['status'] == 'pending').length;
    final completedCount = _schedules.where((s) => s['status'] == 'completed').length;
    final todaySchedules = _schedules.where((s) => _isScheduleToday(s['shift_date'] ?? '')).toList();

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: AppTheme.primaryBrand,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          // ── Top App Bar ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 64,
            titleSpacing: AppTheme.spMd,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBrand.withValues(alpha: 0.5), width: 1.5),
                      color: AppTheme.primaryBrand.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.business, color: AppTheme.primaryBrand, size: 20),
                  );
                },
              ),
            ),
            title: Text(
              _user?['company'] ?? 'Building Management',
              style: AppTheme.titleLg.copyWith(
                color: AppTheme.primaryBrand,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
            actions: [
              // Notification bell with badge
              ListenableBuilder(
                listenable: NotificationProvider.of(context),
                builder: (context, _) {
                  final notificationService = NotificationProvider.of(context);
                  final unreadCount = notificationService.unreadCount;
                  
                  return IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface, size: 26),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.alertCritical,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/notifications');
                    },
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Real-time Employee Task Status Banner ────────────────────
          SliverToBoxAdapter(
            child: _TaskStatusBanner(
              pendingCount: pendingCount,
              completedCount: completedCount,
              totalCount: _schedules.length,
              schedules: _schedules,
              onTinjau: () => Navigator.of(context).pushNamed('/my-tasks'),
            ),
          ),

          // ── Stat Cards 2×2 Grid ─────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spMd, AppTheme.spMd, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppTheme.spSm,
                crossAxisSpacing: AppTheme.spSm,
                childAspectRatio: 1.9,
              ),
              delegate: SliverChildListDelegate([
                _StatCard(
                  label: 'TOTAL GEDUNG',
                  value: '12',
                  icon: Icons.domain_outlined,
                ),
                _StatCard(
                  label: 'PERALATAN AKTIF',
                  value: '85%',
                  icon: Icons.settings_input_component_outlined,
                  valueColor: AppTheme.statusOk,
                ),
                _StatCard(
                  label: 'JADWAL TUGAS',
                  value: '$pendingCount Aktif',
                  icon: Icons.people_outline,
                ),
                _StatCard(
                  label: 'STATUS SISTEM',
                  value: 'Stabil',
                  icon: Icons.verified_outlined,
                  valueColor: AppTheme.statusOk,
                  valueSize: 20,
                ),
              ]),
            ),
          ),

          // ── Attendance Card ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spSm, AppTheme.spMd, 0),
              child: _AttendanceStatusCard(
                attendance: _todayAttendance,
                isLoaded: _attendanceLoaded,
                onTap: () => Navigator.of(context).pushNamed('/attendance').then((_) {
                  _apiService.getTodayAttendance().then((att) {
                    if (mounted) setState(() { _todayAttendance = att; _attendanceLoaded = true; });
                  }).catchError((_) {});
                }),
              ),
            ),
          ),

          // ── Check-in Checkpoint wide card ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spSm, AppTheme.spMd, 0),
              child: _CheckpointCard(
                total: _schedules.length,
                completed: completedCount,
              ),
            ),
          ),

          // ── Quick Actions ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spMd, AppTheme.spMd, 0),
              child: _QuickActions(
                onJadwalTugas: () => Navigator.of(context).pushNamed('/my-tasks'),
              ),
            ),
          ),

          // ── Insiden Harian ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spXl, AppTheme.spMd, 0),
              child: _InsidenSection(reports: _reports),
            ),
          ),

          // ── Progres Tugas Hari Ini ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spXl, AppTheme.spMd, 0),
              child: _TaskProgressCard(schedules: todaySchedules),
            ),
          ),

          // ── Aktivitas Terbaru ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spXl, AppTheme.spMd, 0),
              child: _AktivitasSection(
                reports: _reports,
                schedules: todaySchedules,
                onCheckIn: (s) => _openTaskDetail(
                    initialIndex: _schedules.indexOf(s)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spXl)),
        ],
      ),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final role = _user?['role'] as String? ?? 'worker';
    final isAdmin = role == 'admin' || role == 'viewer';

    final items = [
      _NavItem(icon: Icons.grid_view_rounded, label: 'Home'),
      _NavItem(icon: Icons.fingerprint_rounded, label: 'Absensi'),
      _NavItem(icon: Icons.assignment_outlined, label: 'Reports'),
      _NavItem(
        icon: isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
        label: isAdmin ? 'Admin' : 'Profile',
      ),
    ];

    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _selectedTab == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i == 3) {
                      final role = _user?['role'] as String? ?? 'worker';
                      if (role == 'admin' || role == 'viewer') {
                        Navigator.of(context).pushNamed('/admin-dashboard');
                      } else {
                        Navigator.of(context).pushNamed('/profile');
                      }
                      return;
                    }
                    if (i == 2) {
                      Navigator.of(context).pushNamed('/activity-log');
                      return;
                    }
                    if (i == 1) {
                      Navigator.of(context).pushNamed('/attendance').then((_) {
                        _apiService.getTodayAttendance().then((att) {
                          if (mounted) setState(() { _todayAttendance = att; _attendanceLoaded = true; });
                        }).catchError((_) {});
                      });
                      return;
                    }
                    setState(() => _selectedTab = i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40, height: 28,
                        decoration: selected
                            ? BoxDecoration(
                                color: AppTheme.primaryBrand.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              )
                            : null,
                        child: Icon(
                          items[i].icon,
                          color: selected ? AppTheme.primaryBrand : cs.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].label,
                        style: AppTheme.labelSm.copyWith(
                          color: selected ? AppTheme.primaryBrand : cs.onSurfaceVariant,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
//  Attendance Status Card (Dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceStatusCard extends StatelessWidget {
  final Map<String, dynamic>? attendance;
  final bool isLoaded;
  final VoidCallback onTap;

  const _AttendanceStatusCard({
    required this.attendance,
    required this.isLoaded,
    required this.onTap,
  });

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

  String _statusLabel(String? s) => switch (s) {
        'Hadir' => 'Hadir',
        'Terlambat' => 'Terlambat',
        'Alpa' => 'Alpa',
        _ => 'Belum Absen',
      };

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

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final status     = attendance?['status'] as String?;
    final clockIn    = attendance?['clock_in_time'] as String?;
    final clockOut   = attendance?['clock_out_time'] as String?;
    final color      = _statusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        ),
        child: !isLoaded
            ? Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spMd),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 80, height: 10, decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  )),
                  const SizedBox(height: 6),
                  Container(width: 120, height: 14, decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  )),
                ]),
              ])
            : Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_statusIcon(status), color: color, size: 24),
                  ),
                  const SizedBox(width: AppTheme.spMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Absensi Hari Ini',
                          style: AppTheme.labelMd.copyWith(
                              color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusLabel(status),
                          style: AppTheme.bodyLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        if (clockIn != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Masuk ${_fmtTime(clockIn)}${clockOut != null ? '  ·  Keluar ${_fmtTime(clockOut)}' : ''}',
                            style: AppTheme.labelSm.copyWith(
                                color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.outline, size: 20),
                ],
              ),
      ),
    );
  }
}



/// Real-time employee task status banner replacing legacy critical alarm banner
class _TaskStatusBanner extends StatelessWidget {
  final int pendingCount;
  final int completedCount;
  final int totalCount;
  final List<dynamic> schedules;
  final VoidCallback onTinjau;

  const _TaskStatusBanner({
    required this.pendingCount,
    required this.completedCount,
    required this.totalCount,
    required this.schedules,
    required this.onTinjau,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasPending = pendingCount > 0;
    
    // Find first pending schedule for real-time hint
    String hintText = '';
    if (hasPending) {
      final firstPending = schedules.firstWhere(
        (s) => s['status'] == 'pending',
        orElse: () => null,
      );
      if (firstPending != null && firstPending is Map) {
        final cp = firstPending['checkpoint'] as Map<String, dynamic>?;
        final cpName = cp?['name'] as String? ?? 'Tugas Lapangan';
        final timeStr = firstPending['scheduled_time']?.toString();
        final time = (timeStr != null && timeStr.length >= 5) ? timeStr.substring(0, 5) : '';
        hintText = time.isNotEmpty ? '$cpName ($time WIB)' : cpName;
      } else {
        hintText = '$completedCount dari $totalCount tugas telah diselesaikan';
      }
    } else if (totalCount > 0) {
      hintText = 'Seluruh $totalCount tugas hari ini telah diselesaikan';
    } else {
      hintText = 'Tidak ada penugasan aktif hari ini';
    }

    final accentColor = hasPending ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
    final bgColor = hasPending
        ? (isDark ? const Color(0xFF331414) : const Color(0xFFFFEBEE))
        : (isDark ? const Color(0xFF142918) : const Color(0xFFE8F5E9));
    final borderColor = accentColor.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spMd, AppTheme.spMd, 0),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spMd, vertical: AppTheme.spSm + 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPending ? Icons.warning_amber_rounded : Icons.task_alt_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTheme.spSm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending
                      ? '$pendingCount Tugas Karyawan Perlu Dikerjakan'
                      : 'Semua Tugas Selesai',
                  style: AppTheme.bodyLg.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hintText,
                  style: AppTheme.labelMd.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spSm),
          ElevatedButton(
            onPressed: onTinjau,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spMd + 2, vertical: AppTheme.spXs + 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm + 4)),
            ),
            child: Text(
              'Tinjau',
              style: AppTheme.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2-column stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final double valueSize;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.valueSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTheme.labelSm.copyWith(
                    letterSpacing: 0.8,
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: cs.outline),
            ],
          ),
          Text(
            value,
            style: AppTheme.displayLg.copyWith(
              fontSize: valueSize,
              color: valueColor ?? cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wide checkpoint progress card
class _CheckpointCard extends StatelessWidget {
  final int total;
  final int completed;
  const _CheckpointCard({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 18, color: cs.outline),
          const SizedBox(width: AppTheme.spSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHECK-IN CHECKPOINT',
                style: AppTheme.labelSm.copyWith(
                  letterSpacing: 0.8,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$completed',
                      style: AppTheme.displayLg.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' / $total',
                      style: AppTheme.bodyMd.copyWith(
                        fontSize: 16,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Progress ring
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              value: total > 0 ? completed / total : 0,
              strokeWidth: 4,
              backgroundColor: cs.outlineVariant,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBrand),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action – single Jadwal Tugas button
class _QuickActions extends StatelessWidget {
  final VoidCallback onJadwalTugas;

  const _QuickActions({
    required this.onJadwalTugas,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onJadwalTugas,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd, horizontal: AppTheme.spMd),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.primaryBrand.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryBrand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_outlined, size: 24, color: AppTheme.primaryBrand),
            ),
            const SizedBox(width: AppTheme.spMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Tugas',
                    style: AppTheme.bodyLg.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lihat jadwal & tugas hari ini',
                    style: AppTheme.labelSm.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.outline, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Insiden Harian section — shows real issues from reports
class _InsidenSection extends StatelessWidget {
  final List<dynamic> reports;
  const _InsidenSection({required this.reports});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Filter reports that have issues (condition_status == 'Ada Kendala')
    final incidents = reports.where((r) {
      final report = r as Map<String, dynamic>;
      return report['issue'] != null;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Insiden Harian', style: AppTheme.headlineSm.copyWith(color: cs.onSurface)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spSm, vertical: 4),
              decoration: BoxDecoration(
                color: incidents.isEmpty
                    ? AppTheme.statusOk.withValues(alpha: 0.15)
                    : AppTheme.primaryBrand.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: incidents.isEmpty
                      ? AppTheme.statusOk.withValues(alpha: 0.4)
                      : AppTheme.primaryBrand.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Text(
                incidents.isEmpty ? 'Aman' : '${incidents.length} Insiden',
                style: AppTheme.labelSm.copyWith(
                  color: incidents.isEmpty ? AppTheme.statusOk : AppTheme.primaryBrand,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spMd),

        if (incidents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spLg),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: cs.outlineVariant, width: 0.5),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, color: AppTheme.statusOk, size: 36),
                const SizedBox(height: AppTheme.spSm),
                Text('Tidak ada insiden hari ini',
                    style: AppTheme.bodyMd.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Semua checkpoint dalam kondisi baik',
                    style: AppTheme.labelSm.copyWith(color: cs.outline)),
              ],
            ),
          )
        else
          ...incidents.take(3).map((r) {
            final report = r as Map<String, dynamic>;
            final issue = report['issue'] as Map<String, dynamic>;
            final schedule = report['schedule'] as Map<String, dynamic>? ?? {};
            final checkpoint = schedule['checkpoint'] as Map<String, dynamic>? ?? {};
            final user = schedule['user'] as Map<String, dynamic>? ?? {};
            final createdAt = report['created_at'] as String? ?? '';
            final status = issue['status'] as String? ?? 'open';

            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spSm),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: status == 'resolved'
                      ? AppTheme.statusOk.withValues(alpha: 0.4)
                      : AppTheme.primaryBrand.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spMd),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: status == 'resolved'
                                ? AppTheme.statusOk.withValues(alpha: 0.12)
                                : AppTheme.primaryBrand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Icon(
                            status == 'resolved'
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: status == 'resolved'
                                ? AppTheme.statusOk
                                : AppTheme.primaryBrand,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                checkpoint['name'] ?? 'Checkpoint',
                                style: AppTheme.bodyLg.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spXs),
                              Text(
                                issue['issue_description'] as String? ?? 'Kendala terdeteksi',
                                style: AppTheme.bodyMd.copyWith(color: cs.onSurfaceVariant),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppTheme.spXs),
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 14, color: cs.outline),
                                  const SizedBox(width: 4),
                                  Text(
                                    user['name'] ?? 'Pekerja',
                                    style: AppTheme.labelSm.copyWith(color: cs.outline),
                                  ),
                                  const SizedBox(width: AppTheme.spSm),
                                  Icon(Icons.access_time, size: 14, color: cs.outline),
                                  const SizedBox(width: 4),
                                  Text(
                                    _relativeTime(createdAt),
                                    style: AppTheme.labelSm.copyWith(color: cs.outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spSm, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: AppTheme.labelSm.copyWith(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/activity-log'),
                          child: const Text('Lihat Detail'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Color _statusColor(String status) => switch (status) {
        'resolved' => AppTheme.statusOk,
        'in-progress' => AppTheme.statusWarning,
        _ => AppTheme.primaryBrand,
      };

  String _statusLabel(String status) => switch (status) {
        'resolved' => 'Selesai',
        'in-progress' => 'Ditangani',
        _ => 'Terbuka',
      };

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (_) {
      return '';
    }
  }
}

/// Task Progress Card — replaces static energy chart with real schedule completion
class _TaskProgressCard extends StatelessWidget {
  final List<dynamic> schedules;
  const _TaskProgressCard({required this.schedules});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = schedules.length;
    final completed = schedules.where((s) => (s as Map)['status'] == 'completed').length;
    final pending = total - completed;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progres Tugas Hari Ini',
                      style: AppTheme.bodyLg.copyWith(
                          fontWeight: FontWeight.w700, color: cs.onSurface)),
                  Text('$completed dari $total tugas selesai',
                      style: AppTheme.labelMd.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: progress >= 1.0
                      ? AppTheme.statusOk.withValues(alpha: 0.12)
                      : AppTheme.primaryBrand.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: AppTheme.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: progress >= 1.0 ? AppTheme.statusOk : AppTheme.primaryBrand,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spMd),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppTheme.statusOk : AppTheme.primaryBrand,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spMd),

          // Legend
          Row(
            children: [
              _LegendDot(color: AppTheme.statusOk, label: 'Selesai ($completed)'),
              const SizedBox(width: AppTheme.spMd),
              _LegendDot(color: AppTheme.statusWarning, label: 'Pending ($pending)'),
            ],
          ),

          if (total == 0) ...[
            const SizedBox(height: AppTheme.spSm),
            Text(
              'Tidak ada jadwal tugas hari ini.',
              style: AppTheme.labelSm.copyWith(color: cs.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.labelSm.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Aktivitas Terbaru section — real-time from API reports
class _AktivitasSection extends StatelessWidget {
  final List<dynamic> reports;
  final List<dynamic> schedules;
  final Function(Map<String, dynamic>) onCheckIn;

  const _AktivitasSection({
    required this.reports,
    required this.schedules,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    // Build activity list from real reports
    final activities = <_Activity>[];
    for (final r in reports.take(5)) {
      final report = r as Map<String, dynamic>;
      final schedule = report['schedule'] as Map<String, dynamic>? ?? {};
      final checkpoint = schedule['checkpoint'] as Map<String, dynamic>? ?? {};
      final taskCategory = schedule['task_category'] as Map<String, dynamic>? ?? {};
      final user = schedule['user'] as Map<String, dynamic>? ?? {};
      final issue = report['issue'] as Map<String, dynamic>?;
      final createdAt = report['created_at'] as String? ?? '';
      final conditionStatus = report['condition_status'] as String? ?? '';

      final IconData icon;
      final Color iconColor;
      final String title;
      final String subtitle;

      if (issue != null) {
        icon = Icons.warning_amber_rounded;
        iconColor = AppTheme.primaryBrand;
        title = 'Kendala: ${checkpoint['name'] ?? 'Checkpoint'}';
        subtitle = issue['issue_description'] as String? ?? 'Kendala terdeteksi';
      } else if (conditionStatus == 'Baik') {
        icon = Icons.check_circle_outline;
        iconColor = AppTheme.statusOk;
        title = '${checkpoint['name'] ?? 'Checkpoint'} — Baik';
        subtitle = '${user['name'] ?? 'Pekerja'} • ${taskCategory['name'] ?? 'Tugas'}';
      } else {
        icon = Icons.assignment_outlined;
        iconColor = AppTheme.tertiary;
        title = 'Laporan: ${checkpoint['name'] ?? 'Checkpoint'}';
        subtitle = 'Status: $conditionStatus • ${user['name'] ?? 'Pekerja'}';
      }

      activities.add(_Activity(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        time: _relativeTime(createdAt),
      ));
    }

    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivitas Terbaru', style: AppTheme.headlineSm.copyWith(color: cs.onSurface)),
        const SizedBox(height: AppTheme.spMd),

        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spLg),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: cs.outlineVariant, width: 0.5),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, color: cs.outline, size: 36),
                const SizedBox(height: AppTheme.spSm),
                Text('Belum ada aktivitas',
                    style: AppTheme.bodyMd.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Aktivitas akan muncul setelah laporan dikirim',
                    style: AppTheme.labelSm.copyWith(color: cs.outline)),
              ],
            ),
          )
        else
          // Activity items
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: cs.outlineVariant, width: 0.5),
            ),
            child: Column(
              children: [
                ...activities.asMap().entries.map((e) {
                  final isLast = e.key == activities.length - 1;
                  return Column(
                    children: [
                      _ActivityTile(activity: e.value),
                      if (!isLast)
                        Divider(height: 1, indent: 56, color: cs.outlineVariant),
                    ],
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: AppTheme.spMd),

        // "Lihat Semua" button
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/activity-log'),
            child: Text(
              'Lihat Semua Aktivitas',
              style: AppTheme.bodyMd.copyWith(color: AppTheme.primary),
            ),
          ),
        ),

        // Today's schedule (from API) if any
        if (schedules.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spLg),
          Row(
            children: [
              Container(width: 3, height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrand,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppTheme.spSm),
              Text('Jadwal Hari Ini',
                  style: AppTheme.labelMd.copyWith(letterSpacing: 1.2, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: AppTheme.spSm),
          ...schedules.map((s) => _ScheduleTile(
            schedule: s,
            onCheckIn: () => onCheckIn(s),
          )),
        ],
      ],
    );
  }

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (_) {
      return '';
    }
  }
}

class _Activity {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  const _Activity({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle, required this.time,
  });
}

class _ActivityTile extends StatelessWidget {
  final _Activity activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spMd),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: activity.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(activity.icon, color: activity.iconColor, size: 20),
          ),
          const SizedBox(width: AppTheme.spMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: AppTheme.bodyMd.copyWith(
                      color: cs.onSurface, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(activity.subtitle,
                    style: AppTheme.labelMd.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spSm),
          Text(activity.time, style: AppTheme.labelSm.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onCheckIn;
  const _ScheduleTile({required this.schedule, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    final checkpoint = schedule['checkpoint'] ?? {};
    final status     = schedule['status'] ?? 'pending';
    final isPending  = status == 'pending';

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spSm),
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isPending ? AppTheme.primaryBrand.withValues(alpha: 0.4) : cs.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.pending_actions_outlined : Icons.check_circle_outline,
            color: isPending ? AppTheme.statusWarning : AppTheme.statusOk,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spSm),
          Expanded(
            child: Text(checkpoint['name'] ?? '-',
                style: AppTheme.bodyMd.copyWith(color: cs.onSurface)),
          ),
          if (isPending)
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onCheckIn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spSm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                child: const Text('Check In', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CheckIn Dialog  (unchanged from previous version)
// ─────────────────────────────────────────────────────────────────────────────
class CheckInDialog extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final ApiService apiService;
  final String     userName;
  // Returns (reportData, photoBytes, photoLocalPath)
  final void Function(Map<String, dynamic>, Uint8List?, String) onSuccess;

  const CheckInDialog({
    super.key,
    required this.schedule,
    required this.apiService,
    required this.userName,
    required this.onSuccess,
  });

  @override
  State<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<CheckInDialog> {
  final _formKey         = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _issueController = TextEditingController();
  final _picker          = ImagePicker();

  bool      _isGettingLocation = false;
  Position? _currentPosition;
  double?   _distance;

  bool      _isCapturingPhoto = false;
  XFile?    _photoFile;
  Uint8List? _photoBytes;

  String _conditionStatus = 'Aman/Bersih';
  bool   _isSubmitting    = false;

  @override
  void dispose() {
    _notesController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  double _calcDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _getLocation() async {
    setState(() { _isGettingLocation = true; _distance = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('GPS dinonaktifkan.');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak.');
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final cp  = widget.schedule['checkpoint'] ?? {};
      final dist = _calcDistance(pos.latitude, pos.longitude,
          double.parse(cp['latitude'].toString()), double.parse(cp['longitude'].toString()));
      setState(() { _currentPosition = pos; _distance = dist; });
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _takePhoto() async {
    setState(() => _isCapturingPhoto = true);
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 800);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() { _photoFile = photo; _photoBytes = bytes; });
      }
    } catch (e) {
      _showSnack('Gagal mengambil foto: $e', isError: true);
    } finally {
      setState(() => _isCapturingPhoto = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTheme.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurface)),
      backgroundColor: isError ? AppTheme.errorContainer : Theme.of(context).colorScheme.surfaceBright,
    ));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) { _showSnack('Dapatkan GPS terlebih dahulu.', isError: true); return; }
    if (_photoBytes == null) { _showSnack('Ambil foto terlebih dahulu.', isError: true); return; }

    final cp     = widget.schedule['checkpoint'] ?? {};
    final radius = int.parse(cp['radius_meter'].toString());
    if (_distance != null && _distance! > radius) {
      _showSnack('Anda ${(_distance! - radius).ceil()}m di luar jangkauan!', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final reportData = await widget.apiService.submitReport(
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
        _showSnack('Laporan berhasil dikirim!', isError: false);
        Navigator.of(context).pop();
        widget.onSuccess(
          {
            ...reportData,
            'notes':             _notesController.text.trim(),
            'issue_description': _conditionStatus == 'Ada Kendala'
                ? _issueController.text.trim()
                : null,
          },
          _photoBytes,
          _photoFile?.path ?? '',
        );
      }
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp     = widget.schedule['checkpoint'] ?? {};
    final radius = int.parse(cp['radius_meter'].toString());
    final withinRange = _distance != null && _distance! <= radius;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spMd, vertical: AppTheme.spSm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
              ),
              child: Row(children: [
                const Icon(Icons.assignment_outlined, color: AppTheme.primary, size: 22),
                const SizedBox(width: AppTheme.spSm),
                Expanded(child: Text('Form Check-In Tugas', style: AppTheme.titleLg.copyWith(color: Theme.of(context).colorScheme.onSurface))),
                IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.outline, size: 20),
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                ),
              ]),
            ),
            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spMd),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkpoint info
                      _SectionBox(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cp['name'] ?? 'Checkpoint', style: AppTheme.titleLg),
                          const SizedBox(height: AppTheme.spXs),
                          Text('Koordinat: ${cp['latitude']}, ${cp['longitude']}', style: AppTheme.labelMd),
                          Text('Radius: $radius meter', style: AppTheme.labelMd),
                        ],
                      )),
                      const SizedBox(height: AppTheme.spMd),

                      _StepLabel('1. VALIDASI LOKASI GPS', required: true),
                      const SizedBox(height: AppTheme.spSm),
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(
                        onPressed: _isGettingLocation ? null : _getLocation,
                        icon: _isGettingLocation
                            ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onSurface))
                            : const Icon(Icons.gps_fixed, size: 18),
                        label: Text(_isGettingLocation ? 'Mendapatkan lokasi...' : 'Dapatkan GPS'),
                      )),
                      if (_currentPosition != null) ...[
                        const SizedBox(height: AppTheme.spSm),
                        _SectionBox(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}', style: AppTheme.bodyMd),
                            if (_distance != null) ...[
                              const SizedBox(height: AppTheme.spXs),
                              Row(children: [
                                Icon(withinRange ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                                    size: 16, color: withinRange ? AppTheme.statusOk : AppTheme.alertCritical),
                                const SizedBox(width: AppTheme.spXs),
                                Text(
                                  withinRange
                                      ? 'Jarak ${_distance!.toStringAsFixed(1)}m — Valid ✓'
                                      : 'Jarak ${_distance!.toStringAsFixed(1)}m — ${(_distance! - radius).ceil()}m di luar!',
                                  style: AppTheme.bodyMd.copyWith(
                                    color: withinRange ? AppTheme.statusOk : AppTheme.alertCritical),
                                ),
                              ]),
                            ],
                          ],
                        )),
                      ],
                      const SizedBox(height: AppTheme.spMd),

                      _StepLabel('2. FOTO TUGAS', required: true),
                      const SizedBox(height: AppTheme.spSm),
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(
                        onPressed: _isCapturingPhoto ? null : _takePhoto,
                        icon: _isCapturingPhoto
                            ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onSurface))
                            : const Icon(Icons.camera_alt_outlined, size: 18),
                        label: Text(_photoBytes != null ? 'Ambil Ulang Foto' : 'Ambil Foto'),
                      )),
                      if (_photoBytes != null) ...[
                        const SizedBox(height: AppTheme.spSm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          child: Image.memory(_photoBytes!, height: 160, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spMd),

                      _StepLabel('3. STATUS KONDISI', required: true),
                      const SizedBox(height: AppTheme.spSm),
                      DropdownButtonFormField<String>(
                        initialValue: _conditionStatus,
                        dropdownColor: Theme.of(context).colorScheme.surfaceContainerLow,
                        style: AppTheme.bodyLg.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        items: const [
                          DropdownMenuItem(value: 'Aman/Bersih', child: Text('Aman / Bersih')),
                          DropdownMenuItem(value: 'Ada Kendala', child: Text('Ada Kendala')),
                        ],
                        onChanged: (v) { if (v != null) setState(() => _conditionStatus = v); },
                      ),
                      const SizedBox(height: AppTheme.spMd),

                      _StepLabel('4. CATATAN', required: false),
                      const SizedBox(height: AppTheme.spSm),
                      TextFormField(
                        controller: _notesController, maxLines: 2,
                        style: AppTheme.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        decoration: const InputDecoration(hintText: 'Catatan opsional...'),
                      ),

                      if (_conditionStatus == 'Ada Kendala') ...[
                        const SizedBox(height: AppTheme.spMd),
                        _StepLabel('5. DESKRIPSI KENDALA', required: true, color: AppTheme.alertCritical),
                        const SizedBox(height: AppTheme.spSm),
                        TextFormField(
                          controller: _issueController, maxLines: 3,
                          style: AppTheme.bodyMd.copyWith(color: Theme.of(context).colorScheme.onSurface),
                          decoration: const InputDecoration(hintText: 'Deskripsikan kendala...'),
                          validator: (v) {
                            if (_conditionStatus == 'Ada Kendala' && (v == null || v.trim().isEmpty)) {
                              return 'Wajib diisi jika ada kendala';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spMd),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                )),
                const SizedBox(width: AppTheme.spMd),
                Expanded(flex: 2, child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Laporan'),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog helpers ────────────────────────────────────────────────────────────
class _SectionBox extends StatelessWidget {
  final Widget child;
  const _SectionBox({required this.child});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: child,
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String text;
  final bool required;
  final Color? color;
  const _StepLabel(this.text, {required this.required, this.color});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Text(text, style: AppTheme.labelMd.copyWith(
          letterSpacing: 1.1, color: color ?? cs.onSurfaceVariant)),
      if (required) ...[
        const SizedBox(width: 4),
        Text('(WAJIB)', style: AppTheme.labelSm.copyWith(color: AppTheme.primaryBrand)),
      ],
    ]);
  }
}
