import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notifikasi', style: AppTheme.titleLg),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          if (_notificationService.hasUnread)
            TextButton(
              onPressed: () {
                _notificationService.markAllAsRead();
              },
              child: const Text('Tandai Semua Dibaca'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Hapus Semua'),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _notificationService,
        builder: (context, _) {
          final notifications = _notificationService.notifications;

          if (notifications.isEmpty) {
            return _buildEmpty();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spMd),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spSm),
            itemBuilder: (_, index) {
              return _NotificationTile(
                notification: notifications[index],
                onTap: () {
                  _notificationService.markAsRead(notifications[index].id);
                },
                onDelete: () {
                  _notificationService.deleteNotification(notifications[index].id);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppTheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spMd),
          Text(
            'Tidak ada notifikasi',
            style: AppTheme.headlineSm,
          ),
          const SizedBox(height: AppTheme.spXs),
          Text(
            'Anda akan menerima notifikasi di sini',
            style: AppTheme.bodyMd,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text('Apakah Anda yakin ingin menghapus semua notifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationService.clearAll();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertCritical,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spMd),
        decoration: BoxDecoration(
          color: AppTheme.alertCritical,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          onTap(); // Mark as read
          _handleNotificationTap(context, notification);
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spMd),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? Theme.of(context).colorScheme.surface
                : AppTheme.primaryBrand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: notification.isRead 
                  ? Theme.of(context).colorScheme.outlineVariant
                  : AppTheme.primaryBrand.withValues(alpha: 0.3),
              width: notification.isRead ? 0.5 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spSm),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  size: 20,
                  color: _getTypeColor(notification.type),
                ),
              ),
              const SizedBox(width: AppTheme.spMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTheme.bodyMd.copyWith(
                              fontWeight: notification.isRead 
                                  ? FontWeight.w600 
                                  : FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBrand,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spXs),
                    Text(
                      notification.body,
                      style: AppTheme.bodyMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spXs),
                    Text(
                      _formatTime(notification.timestamp),
                      style: AppTheme.labelSm,
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

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    // Get schedule ID from notification data
    final data = notification.data;
    final scheduleId = data?['schedule_id'] as int?;

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.schedule:
      case NotificationType.reminder:
        // Navigate to My Tasks page with optional schedule ID
        if (scheduleId != null) {
          // Navigate to My Tasks page, which will highlight the specific task
          Navigator.of(context).pushNamed(
            '/my-tasks',
            arguments: {'scheduleId': scheduleId},
          );
        } else {
          Navigator.of(context).pushNamed('/my-tasks');
        }
        break;
        
      case NotificationType.issue:
        // Navigate to activity log (issues shown there)
        Navigator.of(context).pushNamed('/activity-log');
        break;
        
      case NotificationType.report:
        // Navigate to activity log
        Navigator.of(context).pushNamed('/activity-log');
        break;
        
      case NotificationType.system:
        // No specific navigation for system notifications
        break;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    return switch (type) {
      NotificationType.schedule => Icons.calendar_today,
      NotificationType.reminder => Icons.alarm,
      NotificationType.issue => Icons.warning_amber,
      NotificationType.report => Icons.assignment,
      NotificationType.system => Icons.info,
    };
  }

  Color _getTypeColor(NotificationType type) {
    return switch (type) {
      NotificationType.schedule => AppTheme.tertiary,
      NotificationType.reminder => AppTheme.statusWarning,
      NotificationType.issue => AppTheme.alertCritical,
      NotificationType.report => AppTheme.primaryBrand,
      NotificationType.system => AppTheme.secondary,
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${time.day}/${time.month}/${time.year}';
  }
}
