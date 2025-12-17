import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../models/app_notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final notifications = notificationService.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'markAllRead') {
                  await notificationService.markAllAsRead();
                } else if (value == 'clearAll') {
                  await notificationService.clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'markAllRead',
                  child: Text('すべて既読にする'),
                ),
                const PopupMenuItem(
                  value: 'clearAll',
                  child: Text('すべて削除'),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('通知はありません', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.groupInvite:
        return Icons.group_add;
      case NotificationType.sessionCompleted:
        return Icons.check_circle;
      case NotificationType.missionAchieved:
        return Icons.celebration;
      case NotificationType.memberJoined:
        return Icons.person_add;
      case NotificationType.sessionStarted:
        return Icons.alarm;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.groupInvite:
        return Colors.blue;
      case NotificationType.sessionCompleted:
        return Colors.green;
      case NotificationType.missionAchieved:
        return Colors.amber;
      case NotificationType.memberJoined:
        return Colors.teal;
      case NotificationType.sessionStarted:
        return Colors.orange;
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(notification.createdAt);

    if (diff.inDays > 0) {
      return '${diff.inDays}日前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}時間前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.read<NotificationService>();

    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        notificationService.deleteNotification(notification.notificationId);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor().withOpacity(0.1),
          child: Icon(_getIcon(), color: _getColor()),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.message),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getTimeAgo(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () async {
          if (!notification.isRead) {
            await notificationService.markAsRead(notification.notificationId);
          }
          // TODO: 通知タップ時の詳細画面遷移
        },
      ),
    );
  }
}
