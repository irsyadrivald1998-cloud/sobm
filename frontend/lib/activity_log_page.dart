import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'activity_log_notifier.dart';
import 'main.dart' show ActivityLogProvider;

// ─────────────────────────────────────────────────────────────────────────────
//  ActivityLogPage  —  "Log Aktivitas Lapangan"
//  Listens to ActivityLogNotifier — updates in real time when reports come in
// ─────────────────────────────────────────────────────────────────────────────
class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final _scrollController  = ScrollController();
  final _messageController = TextEditingController();
  final _focusNode         = FocusNode();

  bool   _isLoading = false;
  // ignore: unused_field
  String _error     = '';

  @override
  void initState() {
    super.initState();
    // If notifier has no entries yet, trigger a load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ActivityLogProvider.of(context);
      if (notifier.entries.isEmpty) _load();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Refresh from API (pull-to-refresh) ───────────────────────────────────
  Future<void> _load() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final api       = ApiService();
      final reports   = await api.getReports().catchError((_) => <dynamic>[]);
      final schedules = await api.getSchedules().catchError((_) => <dynamic>[]);
      if (mounted) {
        ActivityLogProvider.of(context).seedFromApi(reports, schedules);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Send chat message ─────────────────────────────────────────────────────
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    ActivityLogProvider.of(context).pushChatMessage(
      actor: 'Saya',
      body:  text,
    );
    _messageController.clear();
    _focusNode.requestFocus();
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Group entries by date label ───────────────────────────────────────────
  Map<String, List<ActivityLogEntry>> _grouped(List<ActivityLogEntry> entries) {
    final now = DateTime.now();
    final Map<String, List<ActivityLogEntry>> groups = {};
    for (final e in entries) {
      final d = e.date;
      String label;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        label = 'Hari Ini';
      } else if (DateTime(d.year, d.month, d.day) ==
          DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1))) {
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
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceLowest,
      leading: const Padding(
        padding: EdgeInsets.only(left: AppTheme.spMd),
        child: Icon(Icons.tag, color: AppTheme.onSurfaceVariant, size: 22),
      ),
      leadingWidth: 40,
      title: Text('Log Aktivitas Lapangan', style: AppTheme.titleLg),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.onSurfaceVariant),
          onPressed: _load,
        ),
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, color: AppTheme.outlineVariant),
      ),
    );
  }

  // ── Body: loading / error / timeline ─────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBrand));
    }

    // Listen to notifier — rebuilds whenever entries change
    return ListenableBuilder(
      listenable: ActivityLogProvider.of(context),
      builder: (context, _) {
        final entries = ActivityLogProvider.of(context).entries;
        return RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.primaryBrand,
          backgroundColor: AppTheme.surface,
          child: entries.isEmpty
              ? _buildEmpty()
              : _buildTimeline(entries),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: AppTheme.outline, size: 56),
                const SizedBox(height: AppTheme.spMd),
                Text('Belum ada aktivitas',
                    style: AppTheme.bodyMd),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────────
  Widget _buildTimeline(List<ActivityLogEntry> entries) {
    final grouped   = _grouped(entries);
    final groupKeys = grouped.keys.toList();
    final totalItems = groupKeys.fold<int>(
        0, (sum, k) => sum + 1 + (grouped[k]?.length ?? 0));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppTheme.spMd),
      itemCount: totalItems,
      itemBuilder: (context, idx) {
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
    );
  }

  Widget _buildEntryTile(ActivityLogEntry entry) {
    switch (entry.type) {
      case LogEntryType.system: return _SystemBubble(entry: entry);
      case LogEntryType.user:   return _UserBubble(entry: entry);
      case LogEntryType.alert:  return _AlertBubble(entry: entry);
    }
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLow,
        border: Border(
            top: BorderSide(color: AppTheme.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spMd, vertical: AppTheme.spSm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attach
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppTheme.outlineVariant, width: 0.5),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.outline, size: 22),
                ),
              ),
              const SizedBox(width: AppTheme.spSm),

              // Text field
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Kirim pesan ke #log-aktivitas...',
                      hintStyle:
                          AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                      filled: true,
                      fillColor: AppTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spMd,
                          vertical: AppTheme.spSm + 2),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        borderSide: const BorderSide(
                            color: AppTheme.outlineVariant, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        borderSide: const BorderSide(
                            color: AppTheme.outlineVariant, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBrand, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spSm),

              // Send / emoji toggle
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
//  Date Divider
// ─────────────────────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final String label;
  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
      child: Row(children: [
        const Expanded(child: Divider(color: AppTheme.outlineVariant, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spMd),
          child: Text(label,
              style: AppTheme.labelMd.copyWith(color: AppTheme.outline)),
        ),
        const Expanded(child: Divider(color: AppTheme.outlineVariant, thickness: 0.5)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bubble Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Color  bgColor;
  final Color? borderColor;
  final Widget child;
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

/// System BMS bubble
class _SystemBubble extends StatelessWidget {
  final ActivityLogEntry entry;
  const _SystemBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spMd, 0, AppTheme.spMd, AppTheme.spMd),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(
          bgColor: AppTheme.surfaceHighest,
          child: const Icon(Icons.settings_outlined,
              color: AppTheme.onSurfaceVariant, size: 20),
        ),
        const SizedBox(width: AppTheme.spSm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            if (entry.photoUrl != null) ...[
              const SizedBox(height: AppTheme.spSm),
              _PhotoCard(
                photoUrl:  entry.photoUrl!,
                workOrder: entry.workOrder ?? '',
                source:    entry.source    ?? '',
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// User text bubble
class _UserBubble extends StatelessWidget {
  final ActivityLogEntry entry;
  const _UserBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spMd, 0, AppTheme.spMd, AppTheme.spMd),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(
          bgColor: entry.avatarColor ?? AppTheme.surfaceHighest,
          child: Icon(entry.avatarIcon ?? Icons.person,
              color: AppTheme.onSurface, size: 20),
        ),
        const SizedBox(width: AppTheme.spSm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          ]),
        ),
      ]),
    );
  }
}

/// Critical alert bubble — red left border
class _AlertBubble extends StatelessWidget {
  final ActivityLogEntry entry;
  const _AlertBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spMd, 0, AppTheme.spMd, AppTheme.spMd),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(
          bgColor:     AppTheme.errorContainer,
          borderColor: AppTheme.alertCritical,
          child: const Icon(Icons.warning_amber_rounded,
              color: AppTheme.alertCritical, size: 20),
        ),
        const SizedBox(width: AppTheme.spSm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            Container(
              decoration: BoxDecoration(
                color: AppTheme.errorContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border(
                  left:   const BorderSide(color: AppTheme.alertCritical, width: 3),
                  top:    BorderSide(color: AppTheme.alertCritical.withOpacity(0.3), width: 0.5),
                  right:  BorderSide(color: AppTheme.alertCritical.withOpacity(0.3), width: 0.5),
                  bottom: BorderSide(color: AppTheme.alertCritical.withOpacity(0.3), width: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(AppTheme.spMd),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: const BoxDecoration(
                        color: AppTheme.alertCritical, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(entry.alertTitle ?? entry.body,
                        style: AppTheme.bodyLg.copyWith(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                if (entry.alertTitle != null && entry.body.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spXs),
                  Text(entry.body,
                      style: AppTheme.bodyMd,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Photo Card
// ─────────────────────────────────────────────────────────────────────────────
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 140,
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Placeholder(),
                  )
                : _Placeholder(),
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.spSm + 2),
            color: AppTheme.surfaceHigh,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LAMPIRAN WORK ORDER',
                  style: AppTheme.labelSm
                      .copyWith(color: AppTheme.outline, letterSpacing: 0.8)),
              const SizedBox(height: AppTheme.spXs),
              Row(children: [
                Text(workOrder,
                    style: AppTheme.bodyMd.copyWith(
                        color: AppTheme.tertiary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new, size: 14, color: AppTheme.tertiary),
              ]),
              const SizedBox(height: 2),
              Text(source, style: AppTheme.labelSm),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.surfaceHigh,
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppTheme.outline, size: 40),
        ),
      );
}
