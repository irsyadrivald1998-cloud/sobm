import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'main.dart' show ThemeProvider;

// ─────────────────────────────────────────────────────────────────────────────
//  AdminDashboardPage — Admin profile & system overview
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  
  // Mock statistics - in real app, fetch from API
  final Map<String, dynamic> _stats = {
    'totalUsers': 45,
    'activeWorkers': 32,
    'pendingTasks': 18,
    'completedToday': 24,
    'totalAreas': 12,
    'totalCheckpoints': 156,
    'issuesReported': 7,
    'reportsToday': 28,
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _api.getUser();
    setState(() { 
      _user = data;
      _isLoading = false;
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              nav.pop();
              await _api.logout();
              nav.pushReplacementNamed('/');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeN = ThemeProvider.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand)),
      );
    }

    final name = _user?['name'] as String? ?? 'Admin';
    final employeeId = _user?['employee_id'] as String? ?? '-';
    final role = (_user?['role'] as String? ?? 'admin').toUpperCase();
    final email = _user?['email'] as String? ?? '-';

    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero Header with Admin Info ───────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _AdminHeader(
                name: name,
                role: role,
                initials: initials,
                isDark: isDark,
                email: email,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Divider(height: 0.5, color: cs.outlineVariant),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spMd),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Quick Stats Grid ──────────────────────────────────────────
                _SectionHeader('Ringkasan Sistem', Icons.dashboard),
                _QuickStatsGrid(stats: _stats),

                // ── System Health Chart ───────────────────────────────────────
                const SizedBox(height: AppTheme.spLg),
                _SectionHeader('Aktivitas Minggu Ini', Icons.analytics),
                _WeeklyActivityChart(),

                // ── Quick Actions ─────────────────────────────────────────
                const SizedBox(height: AppTheme.spLg),
                _SectionHeader('Aksi Cepat', Icons.flash_on),
                _QuickActionsGrid(),

                // ── Admin Profile Details ─────────────────────────────────────
                const SizedBox(height: AppTheme.spLg),
                _SectionHeader('Informasi Profil', Icons.person),
                _AdminProfileCard(
                  employeeId: employeeId,
                  email: email,
                  role: role,
                ),

                // ── Account Settings ──────────────────────────────────────────
                const SizedBox(height: AppTheme.spLg),
                _SectionHeader('Pengaturan Akun', Icons.settings),
                _SettingsCard(children: [
                  _SwitchTile(
                    icon: Icons.light_mode_outlined,
                    iconColor: const Color(0xFFFBBF24),
                    title: 'Mode Terang',
                    subtitle: 'Aktifkan tampilan light mode',
                    value: themeN.isLight,
                    onChanged: (_) => themeN.toggle(),
                  ),
                  const _DividerLine(),
                  _NavTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppTheme.tertiary,
                    title: 'Notifikasi Admin',
                    subtitle: 'Kelola notifikasi sistem',
                    onTap: () => _showComingSoon(context),
                  ),
                  const _DividerLine(),
                  _NavTile(
                    icon: Icons.security,
                    iconColor: AppTheme.statusWarning,
                    title: 'Keamanan',
                    subtitle: 'Pengaturan keamanan admin',
                    onTap: () => _showSecuritySettings(context),
                  ),
                ]),

                // ── System Management ─────────────────────────────────────────
                const SizedBox(height: AppTheme.spLg),
                _SectionHeader('Manajemen Sistem', Icons.admin_panel_settings),
                _SettingsCard(children: [
                  _NavTile(
                    icon: Icons.people_outline,
                    iconColor: AppTheme.tertiary,
                    title: 'Kelola Pengguna',
                    subtitle: '${_stats['totalUsers']} pengguna terdaftar',
                    onTap: () => _showComingSoon(context),
                  ),
                  const _DividerLine(),
                  _NavTile(
                    icon: Icons.place_outlined,
                    iconColor: AppTheme.statusOk,
                    title: 'Kelola Area & Checkpoint',
                    subtitle: '${_stats['totalAreas']} area, ${_stats['totalCheckpoints']} checkpoint',
                    onTap: () => _showComingSoon(context),
                  ),
                  const _DividerLine(),
                  _NavTile(
                    icon: Icons.report_problem_outlined,
                    iconColor: AppTheme.statusError,
                    title: 'Kelola Issues',
                    subtitle: '${_stats['issuesReported']} issue dilaporkan',
                    onTap: () => _showComingSoon(context),
                  ),
                  const _DividerLine(),
                  _NavTile(
                    icon: Icons.analytics_outlined,
                    iconColor: AppTheme.primary,
                    title: 'Laporan & Analitik',
                    subtitle: 'Lihat laporan lengkap',
                    onTap: () => _showComingSoon(context),
                  ),
                ]),

                // ── Logout Button ─────────────────────────────────────────────
                const SizedBox(height: AppTheme.spXl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: AppTheme.alertCritical),
                    label: const Text(
                      'Keluar Akun',
                      style: TextStyle(
                        color: AppTheme.alertCritical,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.alertCritical, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spXl),
                Center(
                  child: Text(
                    'SOBM Admin Dashboard\nv1.0.0 © 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: cs.outlineVariant),
                  ),
                ),
                const SizedBox(height: AppTheme.spXl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini akan segera hadir.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSecuritySettings(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: AppTheme.statusWarning),
            SizedBox(width: AppTheme.spSm),
            Text('Pengaturan Keamanan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline, color: AppTheme.primaryBrand),
              title: const Text('Ubah Password'),
              subtitle: const Text('Perbarui kata sandi admin'),
              onTap: () {
                Navigator.pop(ctx);
                _showChangePassword(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint, color: AppTheme.tertiary),
              title: const Text('Autentikasi 2 Faktor'),
              subtitle: const Text('Aktifkan keamanan berlapis'),
              onTap: () {
                Navigator.pop(ctx);
                _showComingSoon(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext ctx) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final conCtrl = TextEditingController();
    
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Password Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Lama',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: AppTheme.spMd),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Baru',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: AppTheme.spMd),
            TextField(
              controller: conCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password',
                prefixIcon: Icon(Icons.lock_clock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showComingSoon(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AdminHeader extends StatelessWidget {
  final String name;
  final String role;
  final String initials;
  final bool isDark;
  final String email;

  const _AdminHeader({
    required this.name,
    required this.role,
    required this.initials,
    required this.isDark,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.surfaceLowest, AppTheme.surface]
              : [AppTheme.lightSurfaceLow, AppTheme.lightSurface],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spXl,
            vertical: AppTheme.spMd,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with crown badge for admin
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBrand.withValues(alpha: 0.3),
                          AppTheme.tertiary.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.primaryBrand,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBrand,
                        ),
                      ),
                    ),
                  ),
                  // Crown badge
                  Positioned(
                    top: -8,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.statusWarning,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.surfaceLowest
                              : AppTheme.lightSurface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.statusWarning.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spMd),
              Text(
                name,
                style: AppTheme.titleLg.copyWith(
                  color: isDark ? AppTheme.onSurface : AppTheme.lightOnSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spXs),
              Text(
                email,
                style: AppTheme.labelMd.copyWith(
                  color: isDark ? AppTheme.onSurfaceVariant : AppTheme.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spSm),
              // Role badge with gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spMd,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBrand,
                      AppTheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBrand.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: AppTheme.spXs),
                    Text(
                      role,
                      style: AppTheme.labelSm.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final IconData icon;
  
  const _SectionHeader(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spXs,
        bottom: AppTheme.spSm,
        top: AppTheme.spSm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBrand),
          const SizedBox(width: AppTheme.spSm),
          Text(
            text,
            style: AppTheme.labelMd.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  
  const _QuickStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final statItems = [
      _StatCardData(
        'Total Users',
        stats['totalUsers'].toString(),
        Icons.people,
        AppTheme.tertiary,
        '+3 hari ini',
      ),
      _StatCardData(
        'Pekerja Aktif',
        stats['activeWorkers'].toString(),
        Icons.work,
        AppTheme.statusOk,
        'dari ${stats['totalUsers']}',
      ),
      _StatCardData(
        'Tugas Pending',
        stats['pendingTasks'].toString(),
        Icons.pending_actions,
        AppTheme.statusWarning,
        'butuh tindakan',
      ),
      _StatCardData(
        'Selesai Hari Ini',
        stats['completedToday'].toString(),
        Icons.task_alt,
        AppTheme.statusOk,
        '100% akurasi',
      ),
      _StatCardData(
        'Total Areas',
        stats['totalAreas'].toString(),
        Icons.place,
        AppTheme.primary,
        '${stats['totalCheckpoints']} checkpoints',
      ),
      _StatCardData(
        'Issues Reported',
        stats['issuesReported'].toString(),
        Icons.report_problem,
        AppTheme.alertCritical,
        'perlu review',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: AppTheme.spSm,
        mainAxisSpacing: AppTheme.spSm,
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) => _StatCard(data: statItems[index]),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCardData(this.title, this.value, this.icon, this.color, this.subtitle);
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  
  const _StatCard({required this.data});

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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: AppTheme.labelSm.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: AppTheme.labelSm.copyWith(
              color: data.color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 40,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[value.toInt()],
                        style: AppTheme.labelSm.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(
              color: cs.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            _createBarGroup(0, 28, AppTheme.tertiary),
            _createBarGroup(1, 32, AppTheme.tertiary),
            _createBarGroup(2, 24, AppTheme.tertiary),
            _createBarGroup(3, 30, AppTheme.tertiary),
            _createBarGroup(4, 35, AppTheme.tertiary),
            _createBarGroup(5, 22, AppTheme.statusWarning),
            _createBarGroup(6, 18, AppTheme.statusWarning),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _createBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        'Buat Jadwal',
        Icons.event_note,
        AppTheme.tertiary,
        () => _showComingSoon(context),
      ),
      _QuickAction(
        'Tambah User',
        Icons.person_add,
        AppTheme.statusOk,
        () => _showComingSoon(context),
      ),
      _QuickAction(
        'Lihat Laporan',
        Icons.description,
        AppTheme.primary,
        () => _showComingSoon(context),
      ),
      _QuickAction(
        'Kelola Area',
        Icons.map,
        AppTheme.statusWarning,
        () => _showComingSoon(context),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: AppTheme.spSm,
        mainAxisSpacing: AppTheme.spSm,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => _QuickActionButton(action: actions[index]),
    );
  }

  void _showComingSoon(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini akan segera hadir.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: cs.outlineVariant, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: AppTheme.spSm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                action.label,
                textAlign: TextAlign.center,
                style: AppTheme.labelSm.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminProfileCard extends StatelessWidget {
  final String employeeId;
  final String email;
  final String role;

  const _AdminProfileCard({
    required this.employeeId,
    required this.email,
    required this.role,
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
        children: [
          _ProfileInfoRow(
            icon: Icons.badge_outlined,
            label: 'Employee ID',
            value: employeeId,
            color: AppTheme.tertiary,
          ),
          const SizedBox(height: AppTheme.spMd),
          _ProfileInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
            color: AppTheme.primary,
          ),
          const SizedBox(height: AppTheme.spMd),
          _ProfileInfoRow(
            icon: Icons.admin_panel_settings,
            label: 'Role',
            value: role,
            color: AppTheme.statusWarning,
          ),
          const SizedBox(height: AppTheme.spMd),
          _ProfileInfoRow(
            icon: Icons.business_outlined,
            label: 'Organisasi',
            value: 'SOBM Facility Management',
            color: AppTheme.outline,
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppTheme.spMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.labelSm.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spMd,
        vertical: AppTheme.spSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppTheme.spMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.labelMd.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryBrand,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showArrow;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : showArrow = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spMd,
          vertical: AppTheme.spSm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppTheme.spMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.labelMd.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(Icons.chevron_right, color: cs.outline, size: 20),
          ],
        ),
      ),
    );
  }
}
