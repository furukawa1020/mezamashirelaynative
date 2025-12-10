// 繧ｰ繝ｫ繝ｼ繝励Δ繝・Ν
class Group {
  final String groupId;
  final String name;
  final String inviteCode; // 6譯∵魚蠕・さ繝ｼ繝・
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

  // 繝・ぅ繝ｼ繝励Μ繝ｳ繧ｯ逕滓・
  String get deepLink => 'mezamashi://join/$inviteCode';

  // SNS蜈ｱ譛臥畑繝・く繧ｹ繝育函謌・
  String getShareText() {
    return '縲・name縲阪↓蜿ょ刈縺励ｈ縺・ｼ―n'
        '諡帛ｾ・さ繝ｼ繝・ $inviteCode\n'
        '縺ｾ縺溘・縺薙・繝ｪ繝ｳ繧ｯ繧偵ち繝・・: $deepLink\n'
        '#繧√＊縺ｾ縺励Μ繝ｬ繝ｼ';
  }
}

enum GroupMode {
  race, // 遶ｶ莠峨Δ繝ｼ繝会ｼ域怙騾溘ｒ遶ｶ縺・ｼ・
  all, // 蜈ｨ蜩｡繧ｯ繝ｪ繧｢繝｢繝ｼ繝会ｼ亥・蜩｡螳御ｺ・〒謌仙粥・・
}
