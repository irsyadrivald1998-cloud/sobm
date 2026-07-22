import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'app_theme.dart';
import 'api_service.dart';
import 'main.dart' show ActivityLogProvider;

// ─────────────────────────────────────────────────────────────────────────────
//  TaskDetailPage — Work Order detail screen
// ─────────────────────────────────────────────────────────────────────────────
class TaskDetailPage extends StatefulWidget {
  final List<dynamic>  schedules;
  final int            initialIndex;
  final Map<String, dynamic>? user;
  final ApiService     apiService;

  const TaskDetailPage({
    super.key,
    required this.schedules,
    required this.apiService,
    this.initialIndex = 0,
    this.user,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late int _selectedIndex;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Map<String, dynamic> get _current =>
      widget.schedules[_selectedIndex] as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── WO Tab chips ────────────────────────────────────────────
          _WoTabBar(
            schedules: widget.schedules,
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
          // ── Detail body ─────────────────────────────────────────────
          Expanded(
            child: _WorkOrderDetail(
              key: ValueKey(_selectedIndex),
              schedule:   _current,
              user:       widget.user,
              apiService: widget.apiService,
              onCompleted: (reportData, photoBytes, photoPath,
                           checklist, notes, issueDesc) {
                // Push to activity log notifier
                ActivityLogProvider.of(context).pushReport(
                  reportData:       reportData,
                  schedule:         _current,
                  userName:         widget.user?['name'] ?? 'Pekerja',
                  photoBytes:       photoBytes,
                  photoLocalPath:   photoPath,
                  notes:            notes,
                  issueDescription: issueDesc,
                );
                Navigator.of(context).pop(true); // signal refresh
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceLowest,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text('Tugas Saya', style: AppTheme.titleLg),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppTheme.onSurface, size: 26),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WO Tab Bar — horizontal scrollable chip row
// ─────────────────────────────────────────────────────────────────────────────
class _WoTabBar extends StatelessWidget {
  final List<dynamic> schedules;
  final int           selectedIndex;
  final ValueChanged<int> onSelect;
  const _WoTabBar({
    required this.schedules,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spMd, vertical: AppTheme.spSm),
        itemCount: schedules.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppTheme.spSm),
        itemBuilder: (_, i) {
          final s        = schedules[i] as Map<String, dynamic>;
          final id       = s['id']?.toString() ?? '${i + 1}';
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spMd, vertical: AppTheme.spXs),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryBrand
                    : AppTheme.surface,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryBrand
                      : AppTheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_outlined,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : AppTheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '#WO-2023-${id.padLeft(3, '0')}',
                    style: AppTheme.labelMd.copyWith(
                      color: selected
                          ? Colors.white
                          : AppTheme.onSurfaceVariant,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WorkOrderDetail — main scrollable body for one WO
// ─────────────────────────────────────────────────────────────────────────────
class _WorkOrderDetail extends StatefulWidget {
  final Map<String, dynamic> schedule;
  final Map<String, dynamic>? user;
  final ApiService apiService;
  final void Function(
    Map<String, dynamic> reportData,
    Uint8List?  photoBytes,
    String      photoPath,
    List<_CheckItem> checklist,
    String?     notes,
    String?     issueDesc,
  ) onCompleted;

  const _WorkOrderDetail({
    super.key,
    required this.schedule,
    required this.apiService,
    required this.onCompleted,
    this.user,
  });

  @override
  State<_WorkOrderDetail> createState() => _WorkOrderDetailState();
}

class _WorkOrderDetailState extends State<_WorkOrderDetail> {
  final _picker       = ImagePicker();
  final _notesCtrl    = TextEditingController();
  final _issueCtrl    = TextEditingController();
  final _sigKey       = GlobalKey();

  Uint8List? _photoBytes;
  String     _photoPath = '';
  bool       _qrScanned = false;
  bool       _isSubmitting = false;
  String     _conditionStatus = 'Aman/Bersih';

  // GPS for check-in
  Position? _position;
  double?   _distance;
  bool      _gettingLocation = false;

  // Signature
  List<Offset?> _sigPoints = [];
  bool          _hasSig    = false;

  // Checklist items — generated from task category
  late List<_CheckItem> _checklist;

  @override
  void initState() {
    super.initState();
    _checklist = _buildChecklist();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _issueCtrl.dispose();
    super.dispose();
  }

  List<_CheckItem> _buildChecklist() {
    final category = widget.schedule['task_category'] as Map<String, dynamic>? ?? {};
    final name     = (category['name'] as String? ?? '').toLowerCase();

    // Generate checklist based on task category keywords
    if (name.contains('hvac') || name.contains('chiller') || name.contains('ac')) {
      return [
        _CheckItem('Periksa tekanan refrigeran'),
        _CheckItem('Cek suhu supply & return'),
        _CheckItem('Inspeksi kondisi filter'),
        _CheckItem('Periksa kebocoran'),
        _CheckItem('Catat pembacaan meter'),
      ];
    } else if (name.contains('listrik') || name.contains('panel') || name.contains('elektrik')) {
      return [
        _CheckItem('Cek kondisi panel listrik'),
        _CheckItem('Periksa koneksi kabel'),
        _CheckItem('Test circuit breaker'),
        _CheckItem('Catat tegangan & arus'),
        _CheckItem('Pastikan grounding aman'),
      ];
    } else if (name.contains('genset') || name.contains('generator')) {
      return [
        _CheckItem('Cek level bahan bakar'),
        _CheckItem('Periksa oli mesin'),
        _CheckItem('Test start genset'),
        _CheckItem('Catat runtime jam'),
        _CheckItem('Periksa baterai starter'),
      ];
    } else if (name.contains('security') || name.contains('keamanan')) {
      return [
        _CheckItem('Patrol area perimeter'),
        _CheckItem('Cek CCTV aktif'),
        _CheckItem('Verifikasi akses pintu'),
        _CheckItem('Lapor kondisi area'),
      ];
    } else {
      return [
        _CheckItem('Inspeksi kondisi area'),
        _CheckItem('Dokumentasi temuan'),
        _CheckItem('Pastikan area bersih'),
        _CheckItem('Laporkan anomali'),
      ];
    }
  }

  // ── GPS ────────────────────────────────────────────────────────────────────
  Future<void> _getLocation() async {
    setState(() { _gettingLocation = true; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('GPS dinonaktifkan.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak.');
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final cp  = widget.schedule['checkpoint'] as Map<String, dynamic>? ?? {};
      double dist = 0;
      try {
        final lat = double.parse(cp['latitude'].toString());
        final lng = double.parse(cp['longitude'].toString());
        const r = 6371000.0;
        final dLat = (lat - pos.latitude) * (pi / 180);
        final dLon = (lng - pos.longitude) * (pi / 180);
        final a = sin(dLat / 2) * sin(dLat / 2) +
            cos(pos.latitude * (pi / 180)) * cos(lat * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);
        dist = r * 2 * atan2(sqrt(a), sqrt(1 - a));
      } catch (_) {}
      setState(() { _position = pos; _distance = dist; });
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  // ── Photo ──────────────────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final photo = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 70, maxWidth: 800);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() { _photoBytes = bytes; _photoPath = photo.path; });
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_position == null) {
      _snack('Dapatkan GPS terlebih dahulu.', isError: true); return;
    }
    if (_photoBytes == null) {
      _snack('Unggah foto terlebih dahulu.', isError: true); return;
    }
    if (!_hasSig) {
      _snack('Tanda tangan wajib diisi.', isError: true); return;
    }

    final cp      = widget.schedule['checkpoint'] as Map<String, dynamic>? ?? {};
    final radius  = int.tryParse(cp['radius_meter']?.toString() ?? '100') ?? 100;
    if (_distance != null && _distance! > radius) {
      _snack('Anda ${(_distance! - radius).ceil()}m di luar jangkauan!',
          isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final reportData = await widget.apiService.submitReport(
        scheduleId:      widget.schedule['id'],
        latitude:        _position!.latitude,
        longitude:       _position!.longitude,
        conditionStatus: _conditionStatus,
        notes:           _notesCtrl.text.trim(),
        issueDescription: _conditionStatus == 'Ada Kendala'
            ? _issueCtrl.text.trim() : null,
        photoBytes: _photoBytes!,
        photoName:  'task_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (mounted) {
        _snack('Tugas berhasil diselesaikan!', isError: false);
        widget.onCompleted(
          {
            ...reportData,
            'notes':             _notesCtrl.text.trim(),
            'issue_description': _conditionStatus == 'Ada Kendala'
                ? _issueCtrl.text.trim() : null,
          },
          _photoBytes,
          _photoPath,
          _checklist,
          _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
          _conditionStatus == 'Ada Kendala' ? _issueCtrl.text.trim() : null,
        );
      }
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface)),
      backgroundColor:
          isError ? AppTheme.errorContainer : AppTheme.statusOk.withOpacity(0.8),
    ));
  }
