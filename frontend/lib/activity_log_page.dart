import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ActivityLogPage  —  "Log Aktivitas Lapangan"
//  Chat-style timeline with system messages, user entries, and alerts
// ─────────────────────────────────────────────────────────────────────────────
class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final ApiService _api = ApiService();
  final _scrollController = ScrollController();

  List<_LogEntry> _entries = [];
  bool   _isLoading = true;
  String _error     = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  final _messageController = TextEditingController();
  final _focusNode         = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      // Pull both reports and schedules; build timeline from reports
      final reports   = await _api.getReports().catchError((_) => <dynamic>[]);
      final schedules = await _api.getSchedules().catchError((_) => <dynamic>[]);

      final List<_LogEntry> entries = [];

      // ── Completed schedule reports from the API ──
      for (final r in reports) {
        final report    = r as Map<String, dynamic>;
        final schedule  = report['schedule']   as Map<String, dynamic>? ?? {};
        final checkpoint= schedule['checkpoint'] as Map<String, dynamic>? ?? {};
        final user      = report['user']       as Map<String, dynamic>? ?? {};
        final issue     = report['issue']      as Map<String, dynamic>?;
        final photo     = report['photo_url']  as String?;
        final createdAt = report['created_at'] as String? ?? '';
        final condition = report['condition_status'] as String? ?? 'Aman/Bersih';
        final notes     = report['notes'] as String? ?? '';

        // System BMS entry (photo upload)
        if (photo != null && photo.isNotEmpty) {
          entries.add(_LogEntry(
            type:      _EntryType.system,
            actor:     'Sistem BMS',
            timestamp: _parseTime(createdAt),
            date:      _parseDate(createdAt),
            body:      '${user['name'] ?? 'Pekerja'} mengunggah foto perbaikan ${checkpoint['name'] ?? 'Checkpoint'}',
            photoUrl:  photo,
            workOrder: 'WO-${report['id'] ?? '0000'}',
            source:    'Ditambahkan via Mobile App',
          ));
        }

        // User text message
        if (notes.isNotEmpty) {
          entries.add(_LogEntry(
            type:      _EntryType.user,
            actor:     user['name'] ?? 'Pekerja',
            timestamp: _parseTime(createdAt),
            date:      _parseDate(createdAt),
            body:      notes,
            avatarIcon: Icons.person,
          ));
        }

        // Critical alert if issue exists
        if (issue != null) {
          final desc = issue['description'] as String? ?? 'Kendala terdeteksi.';
          entries.add(_LogEntry(
            type:      _EntryType.alert,
            actor:     'Sistem Peringatan',
            timestamp: _parseTime(createdAt),
            date:      _parseDate(createdAt),
            body:      desc,
            alertTitle: 'Alarm Kritis: ${checkpoint['name'] ?? 'Checkpoint'}',
          ));
        }
      }

      // ── Fallback: build entries from completed schedules if reports empty ──
      if (entries.isEmpty) {
        final completed = schedules.where((s) => s['status'] == 'completed').toList();
        for (final s in completed) {
          final sc         = s as Map<String, dynamic>;
          final checkpoint = sc['checkpoint']    as Map<String, dynamic>? ?? {};
          final category   = sc['task_category'] as Map<String, dynamic>? ?? {};
          final shiftDate  = sc['shift_date']    as String? ?? '';

          entries.add(_LogEntry(
            type:      _EntryType.system,
            actor:     'Sistem BMS',
            timestamp: sc['scheduled_time'] as String? ?? '00:00',
            date:      _parseDate(shiftDate),
            body:      'Check-in selesai di ${checkpoint['name'] ?? 'Checkpoint'} — ${category['name'] ?? ''}',
            workOrder: 'SCH-${sc['id'] ?? '0'}',
            source:    'Diselesaikan via Mobile App',
          ));
        }
      }

      // Sort by date desc, then add static samples if still empty
      entries.sort((a, b) => b.date.compareTo(a.date));
      if (entries.isEmpty) entries.addAll(_staticSamples());

      setState(() { _entries = entries; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error     = e.toString().replaceAll('Exception: ', '');
        _entries   = _staticSamples();
        _isLoading = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _parseTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h  = dt.hour.toString().padLeft(2, '0');
      final m  = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      return '${h12.toString().padLeft(2,'0')}:$m $period';
    } catch (_) { return ''; }
  }

  DateTime _parseDate(String iso) {
    try { return DateTime.parse(iso).toLocal(); }
    catch (_) { return DateTime.now(); }
  }

  // ── Static fallback samples (match the design screenshot) ─────────────────
  List<_LogEntry> _staticSamples() {
    final today = DateTime.now();
    return [
      _LogEntry(
        type:      _EntryType.system,
        actor:     'Sistem BMS',
        timestamp: '08:15 AM',
        date:      today,
        body:      'Budi S. mengunggah foto perbaikan Chiller Unit 2',
        photoUrl:  '',   // placeholder — will show grey box
        workOrder: 'WO-2023-4412',
        source:    'Ditambahkan via Mobile App',
      ),
      _LogEntry(
        type:        _EntryType.user,
        actor:       'Budi Santoso',
        timestamp:   '09:30 AM',
        date:        today,
        body:        'Sektor B sudah aman, kebocoran pipa sudah ditangani. Tekanan air kembali normal di level 45 PSI.',
        avatarIcon:  Icons.engineering,
        avatarColor: const Color(0xFF8B5A2B),
      ),
      _LogEntry(
        type:       _EntryType.alert,
        actor:      'Sistem Peringatan',
        timestamp:  '11:05 AM',
        date:       today,
        alertTitle: 'Alarm Kritis: Lift 4 macet di Lantai 12',
        body:       'Terdeteksi anomali pada motor penggerak utama. Status: memerlukan teknisi segera.',
      ),
      _LogEntry(
        type:      _EntryType.system,
        actor:     'Sistem BMS',
        timestamp: '13:20 PM',
        date:      today.subtract(const Duration(days: 1)),
        body:      'Genset Backup berhasil diuji. Semua sistem berjalan normal.',
        workOrder: 'WO-2023-4398',
        source:    'Otomatis dari Sistem',
      ),
      _LogEntry(
        type:        _EntryType.user,
        actor:       'Riko Prasetya',
        timestamp:   '14:45 PM',
        date:        today.subtract(const Duration(days: 1)),
        body:        'Pemeriksaan panel listrik Lantai 3 selesai. Ditemukan kabel kendur pada breaker 7, sudah diperbaiki.',
        avatarIcon:  Icons.electric_bolt,
        avatarColor: const Color(0xFF1A5276),
      ),
    ];
  }

  // ── Group entries by date ─────────────────────────────────────────────────
  Map<String, List<_LogEntry>> _grouped() {
    final now   = DateTime.now();
    final Map<String, List<_LogEntry>> groups = {};
    for (final e in _entries) {
      final d = e.date;
      String label;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        label = 'Hari Ini';
      } else if (d.year == now.year && d.month == now.month && d.day == now.day - 1) {
        label = 'Kemarin';
      } else {
        const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
        label = '${d.day} ${months[d.month - 1]} ${d.year}';
      }
      groups.putIfAbsent(label, () => []).add(e);
    }
    return groups;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
          : Column(
              children: [
                Expanded(child: _buildTimeline()),
                _buildInputBar(),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceLowest,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppTheme.spMd),
        child: Icon(Icons.tag, color: AppTheme.onSurfaceVariant, size: 22),
      ),
      leadingWidth: 40,
      title: Text('Log Aktivitas Lapangan', style: AppTheme.titleLg),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppTheme.onSurfaceVariant),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, color: AppTheme.outlineVariant),
      ),
    );
  }

  // ── Timeline list ─────────────────────────────────────────────────────────
  Widget _buildTimeline() {
    final grouped = _grouped();
    final groupKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primaryBrand,
      backgroundColor: AppTheme.surface,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: AppTheme.spMd),
        itemCount: groupKeys.fold<int>(0, (sum, k) => sum + 1 + (grouped[k]?.length ?? 0)),
        itemBuilder: (context, idx) {
          // Map flat index → (group header | entry)
          int cursor = 0;
          for (final key in groupKeys) {
            final items = grouped[key]!;
            if (idx == cursor) return _DateDivider(label: key);
            cursor++;
            if (idx < cursor + items.length) {
              return _buildEntryTile(items[idx - cursor]);
            }
            cursor += items.length;
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEntryTile(_LogEntry entry) {
    switch (entry.type) {
      case _EntryType.system: return _SystemBubble(entry: entry);
      case _EntryType.user:   return _UserBubble(entry: entry);
      case _EntryType.alert:  return _AlertBubble(entry: entry);
    }
  }

  // ── Send a local chat message ─────────────────────────────────────────────
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final h   = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m   = now.minute.toString().padLeft(2, '0');
    final p   = now.hour < 12 ? 'AM' : 'PM';

    final entry = _LogEntry(
      type:       _EntryType.user,
      actor:      'Saya',
      timestamp:  '${h.toString().padLeft(2, '0')}:$m $p',
      date:       now,
      body:       text,
      avatarIcon: Icons.person,
    );

    setState(() => _entries.insert(0, entry));
    _messageController.clear();
    _focusNode.requestFocus();

    // Scroll to top (newest messages appear at top like a chat log)
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Bottom message input bar ──────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLow,
        border: Border(top: BorderSide(color: AppTheme.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spMd, vertical: AppTheme.spSm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attach button
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.outline, size: 22),
                ),
              ),
              const SizedBox(width: AppTheme.spSm),

              // Real TextField
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _messageController,
                    focusNode:  _focusNode,
                    maxLines:   null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Kirim pesan ke #log-aktivitas...',
                      hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                      filled: true,
                      fillColor: AppTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spMd, vertical: AppTheme.spSm + 2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        borderSide: const BorderSide(color: AppTheme.primaryBrand, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spSm),

              // Send / emoji button — switches to send when text is present
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (_, value, __) {
                  final hasText = value.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: hasText ? _sendMessage : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: hasText
                          ? Container(
                              key: const ValueKey('send'),
                              width: 40, height: 40,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBrand,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                            )
                          : const Icon(
                              key: ValueKey('emoji'),
                              Icons.sentiment_satisfied_outlined,
                              color: AppTheme.outline,
                              size: 28,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data Model
// ─────────────────────────────────────────────────────────────────────────────
enum _EntryType { system, user, alert }

class _LogEntry {
  final _EntryType type;
  final String     actor;
  final String     timestamp;
  final DateTime   date;
  final String     body;

  // system-specific
  final String? photoUrl;
  final String? workOrder;
  final String? source;

  // user-specific
  final IconData? avatarIcon;
  final Color?    avatarColor;

  // alert-specific
  final String? alertTitle;

  const _LogEntry({
    required this.type,
    required this.actor,
    required this.timestamp,
    required this.date,
    required this.body,
    this.photoUrl,
    this.workOrder,
    this.source,
    this.avatarIcon,
    this.avatarColor,
    this.alertTitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Date Divider
// ─────────────────────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final String label;
  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.outlineVariant, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spMd),
            child: Text(label,
                style: AppTheme.labelMd.copyWith(color: AppTheme.outline)),
          ),
          const Expanded(child: Divider(color: AppTheme.outlineVariant, thickness: 0.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bubble Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// System BMS bubble — grey icon, optional photo card
class _SystemBubble extends StatelessWidget {
  final _LogEntry entry;
  const _SystemBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spMd, 0, AppTheme.spMd, AppTheme.spMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _Avatar(
            bgColor: AppTheme.surfaceHighest,
            child: const Icon(Icons.settings_outlined,
                color: AppTheme.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: AppTheme.spSm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actor + time
                Row(children: [
                  Text(entry.actor,
                      style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppTheme.spSm),
                  Text(entry.timestamp,
                      style: AppTheme.labelSm.copyWith(color: AppTheme.outline)),
                ]),
                const SizedBox(height: 4),

                // Body text
                Text(entry.body, style: AppTheme.bodyMd),

                // Photo + work order card
                if (entry.photoUrl != null) ...[
                  const SizedBox(height: AppTheme.spSm),
                  _PhotoCard(
                    photoUrl:  entry.photoUrl!,
                    workOrder: entry.workOrder ?? '',
                    source:    entry.source    ?? '',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// User text bubble — avatar with user icon/color
class _UserBubble extends StatelessWidget {
  final _LogEntry entry;
  const _UserBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spMd, 0, AppTheme.spMd, AppTheme.spMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            bgColor: entry.avatarColor ?? AppTheme.surfaceHighest,
            child: Icon(entry.avatarIcon ?? Icons.person,
                color: AppTheme.onSurface, size: 20),
          ),
          const SizedBox(width: AppTheme.spSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(entry.actor,
                      style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppTheme.spSm),
                  Text(entry.timestamp,
                      style: AppTheme.labelSm.copyWith(color: AppTheme.outline)),
                ]),
                const SizedBox(height: 4),
                Text(entry.body, style: AppTheme.bodyMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Critical alert bubble — red left border + red header
class _AlertBubble extends StatelessWidget {
  final _LogEntry entry;
  const _AlertBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.spMd, 0, AppTheme.spMd, AppTheme.spMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red alert icon avatar
          _Avatar(
            bgColor: AppTheme.errorContainer,
            borderColor: AppTheme.alertCritical,
            child: const Icon(Icons.warning_amber_rounded,
                color: AppTheme.alertCritical, size: 20),
          ),
          const SizedBox(width: AppTheme.spSm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actor (red) + time
                Row(children: [
                  Text(entry.actor,
                      style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.alertCritical,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppTheme.spXs),
                  const Icon(Icons.block, size: 12, color: AppTheme.alertCritical),
                  const SizedBox(width: AppTheme.spSm),
                  Text(entry.timestamp,
                      style: AppTheme.labelSm.copyWith(color: AppTheme.outline)),
                ]),
                const SizedBox(height: AppTheme.spSm),

                // Alert card with red left border
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border(
                      left: const BorderSide(color: AppTheme.alertCritical, width: 3),
                      top:    BorderSide(color: AppTheme.alertCritical.withOpacity(0.3), width: 0.5),
                      right:  BorderSide(color: AppTheme.alertCritical.withOpacity(0.3), width: 0.5),
                      bottom: BorderSide(color: AppTheme.alertCritical.withOpacity(0.3), width: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppTheme.spMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: const BoxDecoration(
                              color: AppTheme.alertCritical, shape: BoxShape.circle),
                          ),
                          Expanded(
                            child: Text(
                              entry.alertTitle ?? entry.body,
                              style: AppTheme.bodyLg.copyWith(
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      if (entry.alertTitle != null && entry.body.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spXs),
                        Text(entry.body,
                            style: AppTheme.bodyMd,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Supporting Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Color   bgColor;
  final Color?  borderColor;
  final Widget  child;
  const _Avatar({required this.bgColor, this.borderColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? AppTheme.outlineVariant,
          width: borderColor != null ? 1.5 : 0.5,
        ),
      ),
      child: child,
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String photoUrl;
  final String workOrder;
  final String source;
  const _PhotoCard({
    required this.photoUrl,
    required this.workOrder,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area
            SizedBox(
              height: 140,
              child: photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderPhoto(),
                    )
                  : _PlaceholderPhoto(),
            ),

            // Work order info
            Container(
              padding: const EdgeInsets.all(AppTheme.spSm + 2),
              color: AppTheme.surfaceHigh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAMPIRAN WORK ORDER',
                      style: AppTheme.labelSm.copyWith(
                          color: AppTheme.outline, letterSpacing: 0.8)),
                  const SizedBox(height: AppTheme.spXs),
                  Row(children: [
                    Text(workOrder,
                        style: AppTheme.bodyMd.copyWith(
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new,
                        size: 14, color: AppTheme.tertiary),
                  ]),
                  const SizedBox(height: 2),
                  Text(source, style: AppTheme.labelSm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceHigh,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppTheme.outline, size: 40),
      ),
    );
  }
}
