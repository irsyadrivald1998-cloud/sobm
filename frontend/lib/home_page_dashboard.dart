import 'package:flutter/material.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'main.dart' show ActivityLogProvider;
import 'task_detail_page.dart';

class HomePageDashboard extends StatefulWidget {
  const HomePageDashboard({super.key});
  @override
  State<HomePageDashboard> createState() => _HomePageDashboardState();
}

class _HomePageDashboardState extends State<HomePageDashboard> {
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
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      if (!await _apiService.isLoggedIn()) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
        return;
      }
      final userData      = await _apiService.getUser();
      final schedulesData = await _apiService.getSchedules();
      final reportsData   = await _apiService.getReports()
          .catchError((_) => <dynamic>[]);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
          : _errorMessage.isNotEmpty
              ? _buildError()
              : _buildDashboard(),
    );
  }

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
          SliverToBoxAdapter(child: _CriticalAlarmBanner()),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spSm, AppTheme.spMd, 0),
              child: _CheckpointCard(
                total: _schedules.length,
                completed: completedCount,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spMd, AppTheme.spMd, 0),
              child: _QuickActions(
                onBuatLaporan: () => _openTaskDetail(),
                onScanQR: () => _openTaskDetail(),
                onJadwalTugas: () => _openTaskDetail(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spXl, AppTheme.spMd, 0),
              child: _InsidenSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spMd, AppTheme.spXl, AppTheme.spMd, 0),
              child: _EnergyChart(),
            ),
          ),
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
}

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

class _QuickActions extends StatelessWidget {
  final VoidCallback onBuatLaporan;
  final VoidCallback onScanQR;
  final VoidCallback onJadwalTugas;

  const _QuickActions({
    required this.onBuatLaporan,
    required this.onScanQR,
    required this.onJadwalTugas,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QAction(icon: Icons.add_circle_outline, label: 'Buat\nLaporan', onTap: onBuatLaporan),
      _QAction(icon: Icons.qr_code_scanner_outlined, label: 'Scan\nQR', onTap: onScanQR),
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

class _InsidenSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

class _AktivitasSection extends StatelessWidget {
  final List<dynamic> schedules;
  final Function(Map<String, dynamic>) onCheckIn;

  const _AktivitasSection({required this.schedules, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
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

        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/activity-log'),
            child: Text(
              'Lihat Semua Aktivitas',
              style: AppTheme.bodyMd.copyWith(color: AppTheme.primary),
            ),
          ),
        ),

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
