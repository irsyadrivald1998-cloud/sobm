import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'offline_queue_manager.dart';

class OfflineQueuePage extends StatefulWidget {
  const OfflineQueuePage({super.key});

  @override
  State<OfflineQueuePage> createState() => _OfflineQueuePageState();
}

class _OfflineQueuePageState extends State<OfflineQueuePage> {
  final OfflineQueueManager _queueManager = OfflineQueueManager();
  List<Map<String, dynamic>> _queueItems = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final online = await _queueManager.isOnline();
    if (mounted) {
      setState(() => _isOnline = online);
    }
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final items = await _queueManager.getAllItems();
      if (mounted) {
        setState(() {
          _queueItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _syncQueue() async {
    setState(() => _isSyncing = true);
    
    try {
      final result = await _queueManager.syncPendingItems();
      
      if (mounted) {
        setState(() => _isSyncing = false);
        
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.successCount} item berhasil disinkronkan'),
              backgroundColor: AppTheme.statusOk,
            ),
          );
        } else if (result.hasErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ ${result.successCount} berhasil, ${result.failureCount} gagal',
              ),
              backgroundColor: AppTheme.statusWarning,
            ),
          );
        }
        
        _loadQueue();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal sinkronisasi: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Antrian Offline', style: AppTheme.titleLg),
        backgroundColor: AppTheme.surfaceLowest,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueue,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
          : _buildContent(),
      floatingActionButton: _queueItems.any((item) => item['status'] == 'pending') && _isOnline
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncQueue,
              backgroundColor: _isSyncing ? AppTheme.outline : AppTheme.primaryBrand,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isSyncing ? 'Menyinkronkan...' : 'Sinkronkan Sekarang'),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_queueItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_done,
              size: 64,
              color: AppTheme.statusOk.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spMd),
            Text(
              'Tidak ada antrian',
              style: AppTheme.headlineSm,
            ),
            const SizedBox(height: AppTheme.spXs),
            Text(
              'Semua data sudah tersinkronisasi',
              style: AppTheme.bodyMd,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Connection Status Banner
        Container(
          padding: const EdgeInsets.all(AppTheme.spMd),
          color: _isOnline 
              ? AppTheme.statusOk.withValues(alpha: 0.15)
              : AppTheme.statusWarning.withValues(alpha: 0.15),
          child: Row(
            children: [
              Icon(
                _isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: _isOnline ? AppTheme.statusOk : AppTheme.statusWarning,
              ),
              const SizedBox(width: AppTheme.spSm),
              Expanded(
                child: Text(
                  _isOnline 
                      ? 'Online - Data akan disinkronkan otomatis'
                      : 'Offline - Data akan disimpan dan disinkronkan nanti',
                  style: AppTheme.bodyMd.copyWith(
                    color: _isOnline ? AppTheme.statusOk : AppTheme.statusWarning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Queue Items List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadQueue,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spMd),
              itemCount: _queueItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spSm),
              itemBuilder: (_, index) => _QueueItemTile(
                item: _queueItems[index],
                onDelete: () async {
                  final id = _queueItems[index]['id'] as int;
                  await _queueManager.deleteItem(id);
                  _loadQueue();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QueueItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _QueueItemTile({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String;
    final status = item['status'] as String;
    final createdAt = DateTime.parse(item['created_at'] as String);
    final lastError = item['last_error'] as String?;
    final retryCount = item['retry_count'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(type),
                size: 20,
                color: AppTheme.primaryBrand,
              ),
              const SizedBox(width: AppTheme.spXs),
              Expanded(
                child: Text(
                  _getTypeLabel(type),
                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: AppTheme.labelSm.copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spSm),
          Text(
            _formatDateTime(createdAt),
            style: AppTheme.labelMd,
          ),
          if (retryCount > 0) ...[
            const SizedBox(height: AppTheme.spXs),
            Text(
              'Percobaan: $retryCount kali',
              style: AppTheme.labelSm.copyWith(color: AppTheme.statusWarning),
            ),
          ],
          if (lastError != null) ...[
            const SizedBox(height: AppTheme.spXs),
            Text(
              'Error: $lastError',
              style: AppTheme.labelSm.copyWith(color: AppTheme.alertCritical),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (status == 'failed' || status == 'completed') ...[
            const SizedBox(height: AppTheme.spSm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.alertCritical,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spSm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    return switch (type) {
      'attendance' => Icons.fingerprint,
      'report' => Icons.assignment,
      _ => Icons.inventory,
    };
  }

  String _getTypeLabel(String type) {
    return switch (type) {
      'attendance' => 'Absensi',
      'report' => 'Laporan',
      _ => type,
    };
  }

  String _getStatusLabel(String status) {
    return switch (status) {
      'pending' => 'MENUNGGU',
      'syncing' => 'SINKRON',
      'completed' => 'SELESAI',
      'failed' => 'GAGAL',
      _ => status.toUpperCase(),
    };
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'pending' => AppTheme.statusWarning,
      'syncing' => AppTheme.tertiary,
      'completed' => AppTheme.statusOk,
      'failed' => AppTheme.alertCritical,
      _ => AppTheme.outline,
    };
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
