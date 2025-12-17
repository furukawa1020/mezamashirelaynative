import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_notification.dart';

// 通知サービス
class NotificationService extends ChangeNotifier {
  static const String _notificationsKey = 'mz_notifications';
  final Uuid _uuid = const Uuid();

  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    _loadNotifications();
  }

  // 通知読み込み
  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsStr = prefs.getString(_notificationsKey);
    if (notificationsStr == null) return;

    final List<dynamic> notificationsJson = jsonDecode(notificationsStr);
    _notifications = notificationsJson
        .map((j) => AppNotification.fromJson(j))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // 通知保存
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString(_notificationsKey, jsonEncode(notificationsJson));
  }

  // 通知作成
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final notification = AppNotification(
      notificationId: _uuid.v4(),
      userId: userId,
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      data: data,
    );

    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
  }

  // 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    final index =
        _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index == -1) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    await _saveNotifications();
    notifyListeners();
  }

  // すべて既読にする
  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await _saveNotifications();
    notifyListeners();
  }

  // 通知削除
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.notificationId == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  // 全通知削除
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  // グループ招待通知
  Future<void> notifyGroupInvite({
    required String userId,
    required String groupName,
    required String inviterName,
    required String groupId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.groupInvite,
      title: 'グループ招待',
      message: '$inviterNameさんがあなたを「$groupName」に招待しました',
      data: {'group_id': groupId},
    );
  }

  // セッション完了通知
  Future<void> notifySessionCompleted({
    required String userId,
    required String missionName,
    required String sessionId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.sessionCompleted,
      title: 'セッション完了',
      message: '「$missionName」セッションが完了しました',
      data: {'session_id': sessionId},
    );
  }

  // ミッション達成通知
  Future<void> notifyMissionAchieved({
    required String userId,
    required String missionName,
    required int consecutiveDays,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.missionAchieved,
      title: 'ミッション達成',
      message: '「$missionName」を${consecutiveDays}日間継続達成！',
    );
  }

  // メンバー参加通知
  Future<void> notifyMemberJoined({
    required String userId,
    required String groupName,
    required String memberName,
    required String groupId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.memberJoined,
      title: '新メンバー参加',
      message: '$memberNameさんが「$groupName」に参加しました',
      data: {'group_id': groupId},
    );
  }

  // セッション開始通知
  Future<void> notifySessionStarted({
    required String userId,
    required String groupName,
    required String sessionId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.sessionStarted,
      title: 'セッション開始',
      message: '「$groupName」のセッションが開始されました',
      data: {'session_id': sessionId},
    );
  }
}
