// GRAVITY蠑丞諺蜷阪Θ繝ｼ繧ｶ繝ｼ繝｢繝・Ν
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

  // JSON繧ｷ繝ｪ繧｢繝ｩ繧､繧ｺ
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

  // 陦ｨ遉ｺ蜷榊叙蠕暦ｼ医ル繝・け繝阪・繝譛ｪ險ｭ螳壽凾縺ｯ蛹ｿ蜷崎｡ｨ遉ｺ・・
  String get displayName => nickname ?? '蛹ｿ蜷阪Θ繝ｼ繧ｶ繝ｼ';

  // 繝励Ο繝輔ぅ繝ｼ繝ｫ險ｭ螳壽ｸ医∩縺・
  bool get hasProfile => nickname != null && nickname!.isNotEmpty;
}
