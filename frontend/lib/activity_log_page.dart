import 'dart:async';

import 'package:flutter/material.dart';
import 'activity_log_notifier.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'main.dart' show ActivityLogProvider;

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  Timer? _timer;
  bool _isLoading = false;
  String _error = '';
  LogEntryType? _filterType;

  int _currentPage = 1;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ActivityLogProvider.of(context);
      if (notifier.entries.isEmpty) _load();
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load(isManual: false));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isFetchingMore = true);
    try {
      final api = ApiService();
      _currentPage++;
      final reportsData = await api.getReports(page: _currentPage);
      final schedules = await api.getSchedules(); // Should ideally cache this
      if (mounted) {
        ActivityLogProvider.of(context).appendFromApi(reportsData, schedules);
      }
    } catch (e) {
      // Handle error (perhaps decrement _currentPage)
    } finally {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool isManual = true}) async {
    if (isManual) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final api = ApiService();
      // Updated to fetch paginated reports
      final reportsData = await api.getReports(page: 1);
      final schedules = await api.getSchedules();
      if (mounted) {
        ActivityLogProvider.of(context).seedFromApi(reportsData, schedules);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted && isManual) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Aktivitas Rekan Kerja', style: AppTheme.titleLg),
        backgroundColor: AppTheme.surfaceLowest,
        actions: [
          PopupMenuButton<LogEntryType?>(
            icon: Icon(_filterType == null ? Icons.filter_list : Icons.filter_list_alt),
            onSelected: (type) => setState(() => _filterType = type),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Semua Aktivitas')),
              const PopupMenuItem(value: LogEntryType.system, child: Text('Sistem')),
              const PopupMenuItem(value: LogEntryType.user, child: Text('Laporan Pengguna')),
              const PopupMenuItem(value: LogEntryType.alert, child: Text('Kendala/Alert')),
            ],
          ),
          IconButton(
            tooltip: 'Muat ulang aktivitas',
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _buildError()
              : _buildFeed(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: AppTheme.spMd),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spMd),
            OutlinedButton.icon(
              onPressed: () => _load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return ListenableBuilder(
      listenable: ActivityLogProvider.of(context),
      builder: (context, _) {
        final allEntries = ActivityLogProvider.of(context).entries;
        final filteredEntries = _filterType == null
            ? allEntries
            : allEntries.where((e) => e.type == _filterType).toList();

        if (filteredEntries.isEmpty) {
          return Center(
            child: Text(_filterType == null
              ? 'Belum ada aktivitas laporan.'
              : 'Tidak ada aktivitas dengan filter ini.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () {
            _currentPage = 1;
            return _load();
          },
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppTheme.spMd),
            itemCount: filteredEntries.length + (_isFetchingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spSm),
            itemBuilder: (_, index) {
              if (index == filteredEntries.length) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ));
              }
              return _ActivityTile(entry: filteredEntries[index]);
            },
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityLogEntry entry;

  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.type) {
      LogEntryType.alert => AppTheme.alertCritical,
      LogEntryType.system => AppTheme.primaryBrand,
      LogEntryType.user => AppTheme.tertiary,
    };

    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(entry.type == LogEntryType.alert
              ? Icons.warning_amber_rounded
              : Icons.person_outline, color: color),
          const SizedBox(width: AppTheme.spSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(entry.actor,
                          style: AppTheme.bodyMd
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Text(entry.timestamp, style: AppTheme.labelSm),
                  ],
                ),
                const SizedBox(height: AppTheme.spXs),
                Text(entry.body, style: AppTheme.bodyMd),
                if (entry.workOrder != null) ...[
                  const SizedBox(height: AppTheme.spXs),
                  Text(entry.workOrder!, style: AppTheme.labelSm),
                ],
                if (entry.status != null) ...[
                  const SizedBox(height: AppTheme.spXs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(entry.status!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(entry.status!.toUpperCase(),
                        style: AppTheme.labelSm.copyWith(
                            color: _statusColor(entry.status!), fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'resolved' => AppTheme.statusOk,
    'in-progress' => AppTheme.statusWarning,
    _ => AppTheme.alertCritical,
  };
}
