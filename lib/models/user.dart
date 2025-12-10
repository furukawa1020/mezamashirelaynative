// ユーザーモデル
class AppUser {
  final String userId; // UUID
  String? nickname;
  String? avatarUrl;
  final DateTime createdAt;
  DateTime? lastActiveAt;

  AppUser({
    required this.userId,
    this.nickname,
    this.avatarUrl,
    required this.createdAt,
    this.lastActiveAt,
  });

  // JSONシリアライズ
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'nickname': nickname,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'last_active_at': lastActiveAt?.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    userId: json['user_id'] as String,
    nickname: json['nickname'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    lastActiveAt:
        json['last_active_at'] != null
            ? DateTime.parse(json['last_active_at'] as String)
            : null,
  );

  // 表示名取得（ニックネーム未設定時は匿名表示）
  String get displayName => nickname ?? '匿名ユーザー';

  // プロフィール設定済みか
  bool get hasProfile => nickname != null && nickname!.isNotEmpty;
}
