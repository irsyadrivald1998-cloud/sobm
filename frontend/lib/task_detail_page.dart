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
                // Capture notifier BEFORE pop (context still valid here)
                final notifier = ActivityLogProvider.of(context);
                notifier.pushReport(
                  reportData:       reportData,
                  schedule:         _current,
                  userName:         widget.user?['name'] ?? 'Pekerja',
                  photoBytes:       photoBytes,
                  photoLocalPath:   photoPath,
                  notes:            notes,
                  issueDescription: issueDesc,
                );
                // Now safe to pop
                Navigator.of(context).pop(true);
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
        separatorBuilder: (_, _) =>
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
  final _workDescriptionCtrl = TextEditingController();
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
  final List<Offset?> _sigPoints = [];
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
    _workDescriptionCtrl.dispose();
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
    if (_workDescriptionCtrl.text.trim().isEmpty) {
      _snack('Deskripsi pekerjaan wajib diisi.', isError: true);
      return;
    }

    if (_photoBytes == null) {
      _snack('Unggah foto terlebih dahulu.', isError: true);
      return;
    }

    if (_position == null) {
      _snack('Dapatkan GPS terlebih dahulu.', isError: true);
      return;
    }

    final cp     = widget.schedule['checkpoint'] as Map<String, dynamic>? ?? {};
    final radius = int.tryParse(cp['radius_meter']?.toString() ?? '100') ?? 100;
    if (_distance != null && _distance! > radius) {
      _snack('Lokasi berada di luar radius checkpoint.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final reportData = await widget.apiService.submitReport(
        scheduleId:       widget.schedule['id'],
        latitude:         _position!.latitude,
        longitude:        _position!.longitude,
        conditionStatus:  _conditionStatus,
        workDescription:  _workDescriptionCtrl.text.trim(),
        notes:            _notesCtrl.text.trim(),
        issueDescription: _conditionStatus == 'Ada Kendala'
            ? _issueCtrl.text.trim()
            : null,
        photoBytes: _photoBytes!,
        photoName:
            'task_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (mounted) {
        _snack('Tugas berhasil diselesaikan!', isError: false);

        final fullReport = {
          ...reportData,
          'notes': _notesCtrl.text.trim(),
          'work_description': _workDescriptionCtrl.text.trim(),
          'issue_description': _conditionStatus == 'Ada Kendala'
              ? _issueCtrl.text.trim()
              : null,
        };

        widget.onCompleted(
          fullReport,
          _photoBytes,
          _photoPath,
          _checklist,
          _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
          _conditionStatus == 'Ada Kendala'
              ? _issueCtrl.text.trim()
              : null,
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
          isError ? AppTheme.errorContainer : AppTheme.statusOk.withValues(alpha: 0.8),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final schedule   = widget.schedule;
    final checkpoint = schedule['checkpoint']    as Map<String, dynamic>? ?? {};
    final category   = schedule['task_category'] as Map<String, dynamic>? ?? {};
    final status     = schedule['status'] as String? ?? 'pending';
    final id         = schedule['id']?.toString() ?? '0';
    final time       = schedule['scheduled_time'] as String? ?? '--:--';
    final isPending  = status == 'pending';
    final cp         = checkpoint;
    final radius     = int.tryParse(cp['radius_meter']?.toString() ?? '100') ?? 100;
    final withinRange = _distance != null && _distance! <= radius;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spMd, AppTheme.spMd, AppTheme.spMd, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── WO Header Card ─────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DETAIL PERINTAH KERJA',
                        style: AppTheme.labelSm
                            .copyWith(letterSpacing: 1.0)),
                    _PriorityBadge(isPending: isPending),
                  ],
                ),
                const SizedBox(height: AppTheme.spSm),
                Text(
                  '#WO-2023-${id.padLeft(3, '0')}',
                  style: AppTheme.headlineMd.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spSm),

          // ── Asset Target ───────────────────────────────────────────
          _SectionCard(
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: AppTheme.spMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aset Target',
                          style: AppTheme.labelMd),
                      const SizedBox(height: 2),
                      Text(
                        checkpoint['name'] ?? category['name'] ?? 'Checkpoint',
                        style: AppTheme.bodyLg.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Lantai ${checkpoint['floor'] ?? '-'}',
                        style: AppTheme.bodyMd,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spSm),

          // ── Batas Waktu + Status ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Batas Waktu', style: AppTheme.labelMd),
                      const SizedBox(height: AppTheme.spXs),
                      Text('Hari Ini',
                          style: AppTheme.bodyLg
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(time,
                          style: AppTheme.labelMd
                              .copyWith(color: AppTheme.outline)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spSm),
              Expanded(
                child: _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: AppTheme.labelMd),
                      const SizedBox(height: AppTheme.spXs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isPending ? 'Sedang Berjalan' : 'Selesai',
                              style: AppTheme.bodyLg.copyWith(
                                color: isPending
                                    ? AppTheme.tertiary
                                    : AppTheme.statusOk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: isPending
                                  ? AppTheme.tertiary
                                  : AppTheme.statusOk,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spSm),

          // ── GPS Lokasi ─────────────────────────────────────────────
          _SectionCard(
            onTap: _gettingLocation ? null : _getLocation,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: _gettingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary),
                        )
                      : const Icon(Icons.gps_fixed,
                          color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: AppTheme.spMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _position == null
                            ? 'Validasi Lokasi GPS'
                            : _distance != null
                                ? (withinRange
                                    ? 'Lokasi Valid ✓'
                                    : '${_distance!.toStringAsFixed(1)}m — di luar jangkauan!')
                                : 'Lokasi didapat',
                        style: AppTheme.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _position == null
                              ? AppTheme.onSurface
                              : withinRange
                                  ? AppTheme.statusOk
                                  : AppTheme.alertCritical,
                        ),
                      ),
                      if (_position != null)
                        Text(
                          '${_position!.latitude.toStringAsFixed(5)}, '
                          '${_position!.longitude.toStringAsFixed(5)}',
                          style: AppTheme.labelMd,
                        )
                      else
                        Text('Ketuk untuk validasi',
                            style: AppTheme.labelMd),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppTheme.outline, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spSm),

          // ── Scan QR ────────────────────────────────────────────────
          _SectionCard(
            onTap: () => setState(() => _qrScanned = !_qrScanned),
            highlight: _qrScanned,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _qrScanned
                        ? AppTheme.primaryBrand.withValues(alpha: 0.2)
                        : AppTheme.surfaceHigh,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    _qrScanned
                        ? Icons.check_circle_outline
                        : Icons.qr_code_scanner_outlined,
                    color: _qrScanned
                        ? AppTheme.primaryBrand
                        : AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.spMd),
                Expanded(
                  child: Text(
                    _qrScanned ? 'QR Aset Terverifikasi ✓' : 'Scan QR Aset',
                    style: AppTheme.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _qrScanned
                          ? AppTheme.primaryBrand
                          : AppTheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: _qrScanned
                      ? AppTheme.primaryBrand
                      : AppTheme.outline,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spSm),

          // ── Unggah Foto & Isi Checklist ────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SectionCard(
                  onTap: _pickPhoto,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _photoBytes != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              child: Image.memory(_photoBytes!,
                                  height: 56,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            )
                          : Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppTheme.primary, size: 30),
                      const SizedBox(height: AppTheme.spXs),
                      Text(
                        _photoBytes != null ? 'Foto ✓' : 'Unggah Foto',
                        style: AppTheme.labelMd.copyWith(
                          color: _photoBytes != null
                              ? AppTheme.statusOk
                              : AppTheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spSm),
              Expanded(
                child: _SectionCard(
                  onTap: () => _showChecklistSheet(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist_outlined,
                          color: AppTheme.primary, size: 30),
                      const SizedBox(height: AppTheme.spXs),
                      Text(
                        'Isi Checklist\n'
                        '(${_checklist.where((c) => c.checked).length}'
                        '/${_checklist.length})',
                        style: AppTheme.labelMd,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spMd),

          // ── Kondisi & Catatan ──────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KONDISI', style: AppTheme.labelSm.copyWith(letterSpacing: 1)),
                const SizedBox(height: AppTheme.spSm),
                DropdownButtonFormField<String>(
                  initialValue: _conditionStatus,
                  dropdownColor: AppTheme.surfaceLow,
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Aman/Bersih', child: Text('Aman / Bersih')),
                    DropdownMenuItem(
                        value: 'Ada Kendala', child: Text('Ada Kendala')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _conditionStatus = v);
                  },
                ),
                if (_conditionStatus == 'Ada Kendala') ...[
                  const SizedBox(height: AppTheme.spSm),
                  TextField(
                    controller: _issueCtrl,
                    maxLines: 2,
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                    decoration: const InputDecoration(
                      hintText: 'Deskripsi kendala...',
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spSm),
                Text('DESKRIPSI PEKERJAAN', style: AppTheme.labelSm.copyWith(letterSpacing: 1)),
                const SizedBox(height: AppTheme.spXs),
                TextField(
                  controller: _workDescriptionCtrl,
                  maxLines: 3,
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan pekerjaan yang dilakukan...',
                  ),
                ),
                const SizedBox(height: AppTheme.spSm),
                Text('CATATAN', style: AppTheme.labelSm.copyWith(letterSpacing: 1)),
                const SizedBox(height: AppTheme.spXs),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                  decoration: const InputDecoration(
                    hintText: 'Tambahkan catatan opsional...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spMd),

          // ── Tanda Tangan ───────────────────────────────────────────
          _SignaturePad(
            key: _sigKey,
            onChanged: (hasData) => setState(() => _hasSig = hasData),
          ),
          const SizedBox(height: AppTheme.spXl),

          // ── Selesaikan Button ──────────────────────────────────────
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSubmitting
                    ? AppTheme.outlineVariant
                    : AppTheme.primaryBrand,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPending
                              ? Icons.check_circle_outline
                              : Icons.check_circle,
                          color: Colors.white, size: 22,
                        ),
                        const SizedBox(width: AppTheme.spSm),
                        Text(
                          isPending ? 'Selesaikan' : 'Kirim Ulang Laporan',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChecklistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(AppTheme.spMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Checklist Tugas', style: AppTheme.headlineSm),
              const SizedBox(height: AppTheme.spMd),
              ..._checklist.map((item) => CheckboxListTile(
                value: item.checked,
                onChanged: (v) {
                  setSheet(() => item.checked = v ?? false);
                  setState(() {});
                },
                title: Text(item.label, style: AppTheme.bodyMd),
                activeColor: AppTheme.primaryBrand,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              )),
              const SizedBox(height: AppTheme.spMd),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Signature Pad widget
// ─────────────────────────────────────────────────────────────────────────────
class _SignaturePad extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  const _SignaturePad({super.key, required this.onChanged});

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TANDA TANGAN TEKNISI',
            style: AppTheme.labelSm.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: AppTheme.spSm),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _points.isEmpty
                  ? AppTheme.outlineVariant
                  : AppTheme.primaryBrand.withValues(alpha: 0.5),
              width: 1,
              // dashed look via BoxDecoration not natively supported,
              // using solid thin border instead
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Stack(
              children: [
                if (_points.isEmpty)
                  const Center(
                    child: Text(
                      'Ketuk untuk tanda tangan',
                      style: TextStyle(
                        color: AppTheme.outline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                GestureDetector(
                  onPanStart: (d) {
                    setState(() => _points.add(d.localPosition));
                    widget.onChanged(true);
                  },
                  onPanUpdate: (d) =>
                      setState(() => _points.add(d.localPosition)),
                  onPanEnd: (_) => setState(() => _points.add(null)),
                  child: CustomPaint(
                    painter: _SigPainter(_points),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_points.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _points.clear());
                widget.onChanged(false);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Hapus'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

class _SigPainter extends CustomPainter {
  final List<Offset?> points;
  _SigPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.onSurface
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SigPainter old) => old.points != points;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool highlight;
  const _SectionCard({
    required this.child,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spMd),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: highlight
                ? AppTheme.primaryBrand.withValues(alpha: 0.6)
                : AppTheme.outlineVariant,
            width: highlight ? 1.5 : 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final bool isPending;
  const _PriorityBadge({required this.isPending});

  @override
  Widget build(BuildContext context) {
    final color = isPending ? AppTheme.alertCritical : AppTheme.statusOk;
    final label = isPending ? 'Prioritas Tinggi' : 'Selesai';
    final icon  = isPending ? Icons.warning_amber_outlined : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spSm, vertical: AppTheme.spXs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTheme.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Checklist Item model
// ─────────────────────────────────────────────────────────────────────────────
class _CheckItem {
  final String label;
  bool checked;
  _CheckItem(this.label) : checked = false;
}
