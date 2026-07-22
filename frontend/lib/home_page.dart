import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'api_service.dart';

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
      setState(() {
        _user      = userData;
        _schedules = schedulesData;
        _isLoading = false;
      });
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
        onSuccess: _loadInitialData,
      ),
    );
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
      backgroundColor: AppTheme.background,
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
            backgroundColor: AppTheme.surfaceLowest,
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
              IconButton(
                icon: Stack(clipBehavior: Clip.none, children: [
                  const Icon(Icons.notifications_outlined, color: AppTheme.onSurface, size: 26),
                  Positioned(
                    right: -2, top: -2,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.alertCritical, shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ]),
                onPressed: () {},
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
                onBuatLaporan: () {},
                onScanQR: () {},
                onMonitoring: () {},
                onJadwalTugas: () => setState(() => _selectedTab = 0),
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
              child: _AktivitasSection(schedules: todaySchedules, onCheckIn: _openCheckInDialog),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spXl)),
        ],
      ),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.grid_view_rounded, label: 'Home'),
      _NavItem(icon: Icons.monitor_heart_outlined, label: 'Monitoring'),
      _NavItem(icon: Icons.assignment_outlined, label: 'Reports'),
      _NavItem(icon: Icons.person_outline, label: 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLowest,
        border: Border(top: BorderSide(color: AppTheme.outlineVariant, width: 0.5)),
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
                    if (i == 3) { _handleLogout(); return; }
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
