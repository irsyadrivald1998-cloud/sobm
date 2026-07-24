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
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedTab = 0;

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

      setState(() {
        _user      = userData;
        _schedules = schedulesData;
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
      backgroundColor: AppTheme.surface,
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
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryBrand.withOpacity(0.5), width: 1.5),
                  color: AppTheme.primaryBrand.withOpacity(0.1),
                ),
                child: const Icon(Icons.business, color: AppTheme.primary, size: 20),
              ),
            ),
            title: Text(
              _user?['company'] ?? 'COMPANY X',
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
                        const Icon(Icons.notifications_outlined, color: AppTheme.onSurface, size: 26),
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

          // ── Critical Alarm Banner ───────────────────────────────────
          SliverToBoxAdapter(child: _CriticalAlarmBanner()),

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
                  value: '${pendingCount} Aktif',
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
                onBuatLaporan: () => Navigator.of(context).pushNamed('/my-tasks'),
                onScanQR: () => Navigator.of(context).pushNamed('/my-tasks'),
                onMonitoring: () {},
                onJadwalTugas: () => Navigator.of(context).pushNamed('/my-tasks'),
              ),
            ),
          ),

          // ── Insiden Harian ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spXl, AppTheme.spMd, 0),
              child: _InsidenSection(),
            ),
          ),

          // ── Konsumsi Energi Chart ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spXl, AppTheme.spMd, 0),
              child: _EnergyChart(),
            ),
          ),

          // ── Aktivitas Terbaru ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spXl, AppTheme.spMd, 0),
              child: _AktivitasSection(
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
      _NavItem(icon: Icons.assignment_outlined, label: 'Reports'),
      _NavItem(
        icon: isAdmin ? Icons.admin_panel_settings : Icons.person_outline, 
        label: isAdmin ? 'Admin' : 'Profile',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _selectedTab == i;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (i == 2) { 
                      // Navigate to profile/admin dashboard based on role
                      final role = _user?['role'] as String? ?? 'worker';
                      if (role == 'admin' || role == 'viewer') {
                        Navigator.of(context).pushNamed('/admin-dashboard');
                      } else {
                        Navigator.of(context).pushNamed('/profile');
                      }
                      return; 
                    }
                    if (i == 1) {
                      Navigator.of(context).pushNamed('/activity-log');
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
                                color: AppTheme.primaryBrand.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              )
                            : null,
                        child: Icon(
                          items[i].icon,
                          color: selected ? AppTheme.primaryBrand : AppTheme.outline,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].label,
                        style: AppTheme.labelSm.copyWith(
                          color: selected ? AppTheme.primaryBrand : AppTheme.outline,
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
//  Section Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Red pulse critical alarm banner
class _CriticalAlarmBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spMd, AppTheme.spMd, 0),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spMd, vertical: AppTheme.spSm + 4),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.alertCritical.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.alertCritical, size: 22),
          const SizedBox(width: AppTheme.spSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '4 Alarm Kritis',
                  style: AppTheme.bodyLg.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Tindakan segera diperlukan di Sektor B',
                  style: AppTheme.labelMd.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spSm),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spMd, vertical: AppTheme.spXs + 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            child: Text('Tinjau', style: AppTheme.labelMd.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
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
                  style: AppTheme.labelSm.copyWith(letterSpacing: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: AppTheme.outline),
            ],
          ),
          Text(
            value,
            style: AppTheme.displayLg.copyWith(
              fontSize: valueSize,
              color: valueColor ?? AppTheme.onSurface,
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.outline),
          const SizedBox(width: AppTheme.spSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHECK-IN CHECKPOINT', style: AppTheme.labelSm.copyWith(letterSpacing: 0.8)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$completed',
                      style: AppTheme.displayLg.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' / $total',
                      style: AppTheme.bodyMd.copyWith(fontSize: 16, color: AppTheme.outline),
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
              backgroundColor: AppTheme.outlineVariant,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBrand),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action 4-button row
class _QuickActions extends StatelessWidget {
  final VoidCallback onBuatLaporan;
  final VoidCallback onScanQR;
  final VoidCallback onMonitoring;
  final VoidCallback onJadwalTugas;

  const _QuickActions({
    required this.onBuatLaporan,
    required this.onScanQR,
    required this.onMonitoring,
    required this.onJadwalTugas,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QAction(icon: Icons.add_circle_outline, label: 'Buat\nLaporan', onTap: onBuatLaporan),
      _QAction(icon: Icons.qr_code_scanner_outlined, label: 'Scan\nQR', onTap: onScanQR),
      _QAction(icon: Icons.monitor_outlined, label: 'Moni-\ntoring', onTap: onMonitoring),
      _QAction(icon: Icons.calendar_today_outlined, label: 'Jadwal\nTugas', onTap: onJadwalTugas),
    ];

    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: a == actions.first ? 0 : AppTheme.spXs,
              right: a == actions.last ? 0 : AppTheme.spXs,
            ),
            child: InkWell(
              onTap: a.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, size: 26, color: AppTheme.primary),
                    const SizedBox(height: AppTheme.spXs + 2),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: AppTheme.labelMd.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QAction({required this.icon, required this.label, required this.onTap});
}

/// Insiden Harian section
class _InsidenSection extends StatelessWidget {
  const _InsidenSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Insiden Harian', style: AppTheme.headlineSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spSm, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrand.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.primaryBrand.withOpacity(0.4), width: 0.5),
              ),
              child: Text('Hari Ini',
                  style: AppTheme.labelSm.copyWith(color: AppTheme.primaryBrand)),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spMd),

        // Incident card
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail placeholder
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(Icons.videocam_outlined,
                          color: AppTheme.outline, size: 28),
                    ),
                    const SizedBox(width: AppTheme.spMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kebocoran Pipa HVAC',
                              style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppTheme.spXs),
                          Text(
                            'Terdeteksi penurunan tekanan pada jalur sekunder Lantai 4. Teknisi...',
                            style: AppTheme.bodyMd,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Lihat Detail'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Konsumsi Energi line chart (custom painter)
class _EnergyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Konsumsi Energi', style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                  Text('kWh / Jam Terakhir', style: AppTheme.labelMd),
                ],
              ),
              const Icon(Icons.bolt_outlined, color: AppTheme.tertiary, size: 22),
            ],
          ),
          const SizedBox(height: AppTheme.spMd),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _EnergyChartPainter(),
            ),
          ),
          const SizedBox(height: AppTheme.spSm),
          // X-axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['08', '09', '10', '11', '12', '13']
                .map((t) => Text(t, style: AppTheme.labelSm))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _EnergyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Data points (normalized 0-1)
    const data = [0.45, 0.55, 0.40, 0.72, 0.58, 0.50];
    final w = size.width;
    final h = size.height;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      points.add(Offset(
        i / (data.length - 1) * w,
        h - data[i] * h * 0.85 - 8,
      ));
    }

    // Gradient fill under the line
    final fillPath = Path()..moveTo(points.first.dx, h);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, h);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryBrand.withOpacity(0.3),
            AppTheme.primaryBrand.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Line
    final linePaint = Paint()
      ..color = AppTheme.primaryBrand
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      linePath.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(linePath, linePaint);

    // Peak dot at index 3 (value 0.72)
    canvas.drawCircle(
      points[3],
      5,
      Paint()..color = AppTheme.primaryBrand,
    );
    canvas.drawCircle(
      points[3],
      5,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Dotted vertical line at peak
    final dotPaint = Paint()
      ..color = AppTheme.primaryBrand.withOpacity(0.4)
      ..strokeWidth = 1;
    const dashH = 4.0;
    const gapH  = 4.0;
    double y = points[3].dy + 8;
    while (y < h) {
      canvas.drawLine(Offset(points[3].dx, y), Offset(points[3].dx, y + dashH), dotPaint);
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

/// Aktivitas Terbaru section + schedule list
class _AktivitasSection extends StatelessWidget {
  final List<dynamic> schedules;
  final Function(Map<String, dynamic>) onCheckIn;

  const _AktivitasSection({required this.schedules, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    // Static sample activities that match the design
    final activities = [
      _Activity(
        icon: Icons.elevator_outlined,
        iconColor: AppTheme.statusOk,
        title: 'Lift 4 Maintenance Complete',
        subtitle: 'Teknisi: Budi S. • Gedung Utama',
        time: '10 Min lalu',
      ),
      _Activity(
        icon: Icons.electric_bolt_outlined,
        iconColor: AppTheme.statusWarning,
        title: 'Genset Backup Tested',
        subtitle: 'Sistem otomatis berjalan normal',
        time: '45 Min lalu',
      ),
      _Activity(
        icon: Icons.assignment_outlined,
        iconColor: AppTheme.tertiary,
        title: 'Laporan Dibuat: Panel Listrik',
        subtitle: 'Status: Rusak Ringan • Teknisi: Budi S.',
        time: '2 Jam lalu',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivitas Terbaru', style: AppTheme.headlineSm),
        const SizedBox(height: AppTheme.spMd),

        // Activity items
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
          ),
          child: Column(
            children: [
              ...activities.asMap().entries.map((e) {
                final isLast = e.key == activities.length - 1;
                return Column(
                  children: [
                    _ActivityTile(activity: e.value),
                    if (!isLast)
                      const Divider(height: 1, indent: 56),
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
                  style: AppTheme.labelMd.copyWith(letterSpacing: 1.2)),
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
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spMd),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: activity.iconColor.withOpacity(0.15),
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
                      color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(activity.subtitle,
                    style: AppTheme.labelMd,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spSm),
          Text(activity.time, style: AppTheme.labelSm),
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spSm),
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isPending ? AppTheme.primaryBrand.withOpacity(0.4) : AppTheme.outlineVariant,
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
                style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface)),
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
      content: Text(msg, style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface)),
      backgroundColor: isError ? AppTheme.errorContainer : AppTheme.surfaceHighest,
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
              decoration: const BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
              ),
              child: Row(children: [
                const Icon(Icons.assignment_outlined, color: AppTheme.primary, size: 22),
                const SizedBox(width: AppTheme.spSm),
                Expanded(child: Text('Form Check-In Tugas', style: AppTheme.titleLg)),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.outline, size: 20),
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
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onSurface))
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
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onSurface))
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
                        value: _conditionStatus,
                        dropdownColor: AppTheme.surfaceLow,
                        style: AppTheme.bodyLg.copyWith(color: AppTheme.onSurface),
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
                        style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                        decoration: const InputDecoration(hintText: 'Catatan opsional...'),
                      ),

                      if (_conditionStatus == 'Ada Kendala') ...[
                        const SizedBox(height: AppTheme.spMd),
                        _StepLabel('5. DESKRIPSI KENDALA', required: true, color: AppTheme.alertCritical),
                        const SizedBox(height: AppTheme.spSm),
                        TextFormField(
                          controller: _issueController, maxLines: 3,
                          style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
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
    return Row(children: [
      Text(text, style: AppTheme.labelMd.copyWith(
          letterSpacing: 1.1, color: color ?? AppTheme.onSurfaceVariant)),
      if (required) ...[
        const SizedBox(width: 4),
        Text('(WAJIB)', style: AppTheme.labelSm.copyWith(color: AppTheme.primaryBrand)),
      ],
    ]);
  }
}
