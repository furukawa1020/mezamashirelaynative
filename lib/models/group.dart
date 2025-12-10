// グループモデル
class Group {
  final String groupId;
  final String name;
  final String inviteCode; // 6桁招待コード
  final GroupMode mode;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;

  Group({
    required this.groupId,
    required this.name,
    required this.inviteCode,
    required this.mode,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'name': name,
        'invite_code': inviteCode,
        'mode': mode.name,
        'owner_id': ownerId,
        'member_ids': memberIds,
        'created_at': createdAt.toIso8601String(),
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        groupId: json['group_id'] as String,
        name: json['name'] as String,
        inviteCode: json['invite_code'] as String,
        mode: GroupMode.values.byName(json['mode'] as String),
        ownerId: json['owner_id'] as String,
        memberIds: List<String>.from(json['member_ids'] as List),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  // ディープリンク生成
  String get deepLink => 'mezamashi://join/$inviteCode';

  // SNS共有用テキスト生成
  String getShareText() {
    return '「$name」に参加しよう！\n'
        '招待コード: $inviteCode\n'
        'またはこのリンクをタップ: $deepLink\n'
        '#めざましリレー';
  }
}

enum GroupMode {
  race, // 競争モード（最速を競う）
  all, // 全員クリアモード（全員完了で成功）
}
