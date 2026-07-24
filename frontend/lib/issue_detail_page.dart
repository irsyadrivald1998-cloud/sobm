import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

class IssueDetailPage extends StatefulWidget {
  final Map<String, dynamic> issue;
  final VoidCallback? onStatusUpdated;

  const IssueDetailPage({
    super.key,
    required this.issue,
    this.onStatusUpdated,
  });

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.issue['status'] ?? 'open';
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    
    try {
      final issueId = widget.issue['id'];
      await _apiService.updateIssueStatus(issueId, newStatus);
      
      if (mounted) {
        setState(() => _currentStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Status kendala berhasil diperbarui menjadi ${_statusLabel(newStatus)}'),
              ],
            ),
            backgroundColor: AppTheme.statusOk,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onStatusUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'open' => 'Terbuka',
      'in-progress' => 'Dalam Proses',
      'resolved' => 'Selesai',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'open' => AppTheme.alertCritical,
      'in-progress' => AppTheme.statusWarning,
      'resolved' => AppTheme.statusOk,
      _ => AppTheme.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.issue['report'] as Map<String, dynamic>? ?? {};
    final schedule = report['schedule'] as Map<String, dynamic>? ?? {};
    final checkpoint = schedule['checkpoint'] as Map<String, dynamic>? ?? {};
    final user = report['user'] as Map<String, dynamic>? ?? {};
    final description = widget.issue['description'] ?? 'Tidak ada deskripsi';
    final createdAt = widget.issue['created_at'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Detail Kendala', style: AppTheme.titleLg),
        backgroundColor: AppTheme.surfaceLowest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spMd,
                vertical: AppTheme.spSm,
              ),
              decoration: BoxDecoration(
                color: _statusColor(_currentStatus).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: _statusColor(_currentStatus).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentStatus == 'resolved'
                        ? Icons.check_circle
                        : _currentStatus == 'in-progress'
                            ? Icons.pending
                            : Icons.error,
                    color: _statusColor(_currentStatus),
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spXs),
                  Text(
                    'Status: ${_statusLabel(_currentStatus)}',
                    style: AppTheme.bodyMd.copyWith(
                      color: _statusColor(_currentStatus),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spLg),

            // Location Info
            _InfoCard(
              icon: Icons.location_on_outlined,
              title: 'Lokasi Kendala',
              content: checkpoint['name'] ?? 'Tidak diketahui',
            ),
            const SizedBox(height: AppTheme.spMd),

            // Reporter Info
            _InfoCard(
              icon: Icons.person_outline,
              title: 'Dilaporkan oleh',
              content: user['name'] ?? 'Tidak diketahui',
              subtitle: _formatDate(createdAt),
            ),
            const SizedBox(height: AppTheme.spMd),

            // Description
            Container(
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
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: AppTheme.outline,
                      ),
                      const SizedBox(width: AppTheme.spXs),
                      Text(
                        'Deskripsi Kendala',
                        style: AppTheme.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spSm),
                  Text(description, style: AppTheme.bodyMd),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spXl),

            // Action Buttons (only if not resolved)
            if (_currentStatus != 'resolved') ...[
              Text(
                'Tindakan',
                style: AppTheme.headlineSm,
              ),
              const SizedBox(height: AppTheme.spMd),
              
              if (_currentStatus == 'open')
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _updateStatus('in-progress'),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Mulai Penanganan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusWarning,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
                  ),
                ),
              
              if (_currentStatus == 'in-progress')
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _updateStatus('resolved'),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('Tandai Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusOk,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
                  ),
                ),
            ] else
              Container(
                padding: const EdgeInsets.all(AppTheme.spMd),
                decoration: BoxDecoration(
                  color: AppTheme.statusOk.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: AppTheme.statusOk.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.statusOk),
                    const SizedBox(width: AppTheme.spSm),
                    Expanded(
                      child: Text(
                        'Kendala ini sudah diselesaikan',
                        style: AppTheme.bodyMd.copyWith(
                          color: AppTheme.statusOk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      
      return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year} • $hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final String? subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
    this.subtitle,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spSm),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 24, color: AppTheme.primaryBrand),
          ),
          const SizedBox(width: AppTheme.spMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelMd,
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: AppTheme.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTheme.labelSm,
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
