import 'dart:async';

import 'package:flutter/material.dart';
import 'activity_log_notifier.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'main.dart' show ActivityLogProvider, NotificationProvider;

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
  String? _filterRole;
  String? _filterStatus;
  DateTimeRange? _filterDateRange;

  int _currentPage = 1;
  bool _isFetchingMore = false;
  int _lastEntryCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ActivityLogProvider.of(context);
      if (notifier.entries.isEmpty) _load();
      _lastEntryCount = notifier.entries.length;
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _loadAndNotify());
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAndNotify() async {
    try {
      final api = ApiService();
      final reportsData = await api.getReports(page: 1);
      final schedules = await api.getSchedules();
      
      if (mounted) {
        final notifier = ActivityLogProvider.of(context);
        final oldCount = notifier.entries.length;
        
        notifier.seedFromApi(reportsData, schedules);
        
        final newCount = notifier.entries.length;
        final newEntriesCount = newCount - oldCount;
        
        // Show notification if there are new entries
        if (newEntriesCount > 0 && _lastEntryCount > 0) {
          // Trigger notification service
          final notificationService = NotificationProvider.of(context);
          notificationService.notifyNewReport(
            '$newEntriesCount aktivitas baru dari rekan kerja',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$newEntriesCount aktivitas baru dari rekan kerja',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryBrand,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Lihat',
                textColor: Colors.white,
                onPressed: () {
                  // Scroll to top
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ),
          );
        }
        
        _lastEntryCount = newCount;
      }
    } catch (e) {
      // Silently fail for background polling
    }
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
          IconButton(
            tooltip: 'Filter',
            icon: Icon(
              _hasActiveFilters() ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _hasActiveFilters() ? AppTheme.primaryBrand : null,
            ),
            onPressed: _showFilterDialog,
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

  bool _hasActiveFilters() {
    return _filterType != null || 
           _filterRole != null || 
           _filterStatus != null || 
           _filterDateRange != null;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.spLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Aktivitas', style: AppTheme.headlineSm),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _filterType = null;
                          _filterRole = null;
                          _filterStatus = null;
                          _filterDateRange = null;
                        });
                        setState(() {});
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spMd),
                
                // Filter Type
                Text('Tipe Aktivitas', style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppTheme.spXs),
                Wrap(
                  spacing: AppTheme.spXs,
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: _filterType == null,
                      onSelected: (selected) {
                        setModalState(() => _filterType = null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Sistem'),
                      selected: _filterType == LogEntryType.system,
                      onSelected: (selected) {
                        setModalState(() => _filterType = selected ? LogEntryType.system : null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Pengguna'),
                      selected: _filterType == LogEntryType.user,
                      onSelected: (selected) {
                        setModalState(() => _filterType = selected ? LogEntryType.user : null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Kendala'),
                      selected: _filterType == LogEntryType.alert,
                      onSelected: (selected) {
                        setModalState(() => _filterType = selected ? LogEntryType.alert : null);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spMd),
                
                // Filter Status (for alerts)
                Text('Status Kendala', style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppTheme.spXs),
                Wrap(
                  spacing: AppTheme.spXs,
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: _filterStatus == null,
                      onSelected: (selected) {
                        setModalState(() => _filterStatus = null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Open'),
                      selected: _filterStatus == 'open',
                      onSelected: (selected) {
                        setModalState(() => _filterStatus = selected ? 'open' : null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('In Progress'),
                      selected: _filterStatus == 'in-progress',
                      onSelected: (selected) {
                        setModalState(() => _filterStatus = selected ? 'in-progress' : null);
                        setState(() {});
                      },
                    ),
                    FilterChip(
                      label: const Text('Resolved'),
                      selected: _filterStatus == 'resolved',
                      onSelected: (selected) {
                        setModalState(() => _filterStatus = selected ? 'resolved' : null);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spMd),
                
                // Date Range Filter
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_filterDateRange == null
                      ? 'Pilih Rentang Tanggal'
                      : '${_formatDate(_filterDateRange!.start)} - ${_formatDate(_filterDateRange!.end)}'),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      initialDateRange: _filterDateRange,
                    );
                    if (range != null) {
                      setModalState(() => _filterDateRange = range);
                      setState(() {});
                    }
                  },
                ),
                
                const SizedBox(height: AppTheme.spLg),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _load();
                  },
                  child: const Text('Terapkan Filter'),
                ),
                const SizedBox(height: AppTheme.spSm),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
        
        // Apply all filters
        var filteredEntries = allEntries.where((e) {
          // Filter by type
          if (_filterType != null && e.type != _filterType) return false;
          
          // Filter by status (for alerts)
          if (_filterStatus != null && e.status != _filterStatus) return false;
          
          // Filter by date range
          if (_filterDateRange != null) {
            final entryDate = e.date;
            if (entryDate.isBefore(_filterDateRange!.start) || 
                entryDate.isAfter(_filterDateRange!.end.add(const Duration(days: 1)))) {
              return false;
            }
          }
          
          return true;
        }).toList();

        if (filteredEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.filter_alt_off, size: 48, color: AppTheme.outline),
                const SizedBox(height: AppTheme.spMd),
                Text(
                  _hasActiveFilters()
                    ? 'Tidak ada aktivitas dengan filter ini.'
                    : 'Belum ada aktivitas laporan.',
                  style: AppTheme.bodyLg,
                ),
                if (_hasActiveFilters()) ...[
                  const SizedBox(height: AppTheme.spMd),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterType = null;
                        _filterRole = null;
                        _filterStatus = null;
                        _filterDateRange = null;
                      });
                    },
                    child: const Text('Reset Filter'),
                  ),
                ],
              ],
            ),
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
              return _ActivityTile(
                entry: filteredEntries[index],
                onTap: () {
                  // Navigate to detail page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityDetailPage(entry: filteredEntries[index]),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityLogEntry entry;
  final VoidCallback? onTap;

  const _ActivityTile({required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.type) {
      LogEntryType.alert => AppTheme.alertCritical,
      LogEntryType.system => AppTheme.primaryBrand,
      LogEntryType.user => AppTheme.tertiary,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
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
                  if (entry.type == LogEntryType.alert) ...[
                    const SizedBox(height: AppTheme.spXs),
                    Row(
                      children: [
                        Icon(Icons.touch_app, size: 14, color: AppTheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          'Tap untuk detail',
                          style: AppTheme.labelSm.copyWith(
                            color: AppTheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'resolved' => AppTheme.statusOk,
    'in-progress' => AppTheme.statusWarning,
    _ => AppTheme.alertCritical,
  };
}

/// Detail page for activity log entry
class ActivityDetailPage extends StatelessWidget {
  final ActivityLogEntry entry;

  const ActivityDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.type) {
      LogEntryType.alert => AppTheme.alertCritical,
      LogEntryType.system => AppTheme.primaryBrand,
      LogEntryType.user => AppTheme.tertiary,
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detail Aktivitas'),
        backgroundColor: AppTheme.surfaceLowest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(AppTheme.spMd),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        entry.type == LogEntryType.alert
                            ? Icons.warning_amber_rounded
                            : Icons.person_outline,
                        color: color,
                        size: 32,
                      ),
                      const SizedBox(width: AppTheme.spSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.actor, style: AppTheme.headlineSm),
                            Text(entry.timestamp, style: AppTheme.labelMd),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spMd),
                  const Divider(),
                  const SizedBox(height: AppTheme.spSm),
                  Text('Deskripsi', style: AppTheme.labelMd.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppTheme.spXs),
                  Text(entry.body, style: AppTheme.bodyLg),
                  
                  if (entry.workOrder != null) ...[
                    const SizedBox(height: AppTheme.spMd),
                    Text('Tugas', style: AppTheme.labelMd.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spXs),
                    Text(entry.workOrder!, style: AppTheme.bodyMd),
                  ],
                  
                  if (entry.status != null) ...[
                    const SizedBox(height: AppTheme.spMd),
                    Text('Status', style: AppTheme.labelMd.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spXs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spSm, vertical: AppTheme.spXs),
                      decoration: BoxDecoration(
                        color: _statusColor(entry.status!).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: _statusColor(entry.status!).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _getStatusLabel(entry.status!),
                        style: AppTheme.labelMd.copyWith(
                          color: _statusColor(entry.status!),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Photo section
            if (entry.photoUrl != null || entry.photoBytes != null) ...[
              const SizedBox(height: AppTheme.spLg),
              Text('Foto Laporan', style: AppTheme.headlineSm),
              const SizedBox(height: AppTheme.spSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: entry.photoBytes != null
                    ? Image.memory(
                        entry.photoBytes!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : entry.photoUrl != null
                        ? Image.network(
                            entry.photoUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 200,
                              color: AppTheme.surface,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image, size: 48, color: AppTheme.outline),
                                    SizedBox(height: AppTheme.spSm),
                                    Text('Foto tidak dapat dimuat'),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
            
            // Additional Details
            if (entry.notes != null || entry.issueDescription != null) ...[
              const SizedBox(height: AppTheme.spLg),
              Container(
                padding: const EdgeInsets.all(AppTheme.spMd),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.notes != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.notes, size: 20, color: AppTheme.primaryBrand),
                          const SizedBox(width: AppTheme.spXs),
                          Text('Catatan', style: AppTheme.labelMd.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spXs),
                      Text(entry.notes!, style: AppTheme.bodyMd),
                    ],
                    
                    if (entry.issueDescription != null) ...[
                      if (entry.notes != null) const SizedBox(height: AppTheme.spMd),
                      Row(
                        children: [
                          const Icon(Icons.report_problem, size: 20, color: AppTheme.alertCritical),
                          const SizedBox(width: AppTheme.spXs),
                          Text('Deskripsi Kendala', style: AppTheme.labelMd.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spXs),
                      Text(entry.issueDescription!, style: AppTheme.bodyMd),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'resolved' => AppTheme.statusOk,
        'in-progress' => AppTheme.statusWarning,
        _ => AppTheme.alertCritical,
      };

  String _getStatusLabel(String status) => switch (status) {
        'resolved' => 'Selesai',
        'in-progress' => 'Sedang Dikerjakan',
        'open' => 'Terbuka',
        _ => status.toUpperCase(),
      };
}
