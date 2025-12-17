// アプリ通知モデル
class AppNotification {
  final String notificationId;
  final String userId; // 通知を受け取るユーザー
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // 追加データ（グループID、セッションID等）

  AppNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      notificationId: notificationId,
      userId: userId,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }

  Map<String, dynamic> toJson() => {
    'notification_id': notificationId,
    'user_id': userId,
    'type': type.name,
    'title': title,
    'message': message,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        notificationId: json['notification_id'] as String,
        userId: json['user_id'] as String,
        type: NotificationType.values.byName(json['type'] as String),
        title: json['title'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
        data: json['data'] as Map<String, dynamic>?,
      );
}

enum NotificationType {
  groupInvite, // グループ招待
  sessionCompleted, // セッション完了
  missionAchieved, // ミッション達成
  memberJoined, // メンバー参加
  sessionStarted, // セッション開始
}
