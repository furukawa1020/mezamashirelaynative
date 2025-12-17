// 実績モデル
class Achievement {
  final String achievementId;
  final String userId;
  final AchievementType type;
  final String title;
  final String description;
  final DateTime unlockedAt;
  final int value; // 連続日数や回数など

  Achievement({
    required this.achievementId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.unlockedAt,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'achievement_id': achievementId,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'unlocked_at': unlockedAt.toIso8601String(),
      'value': value,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      achievementId: json['achievement_id'] as String,
      userId: json['user_id'] as String,
      type: AchievementType.values.byName(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      value: json['value'] as int,
    );
  }
}

// 実績タイプ
enum AchievementType {
  firstWakeUp, // 初めての起床
  streak3, // 3日連続
  streak7, // 1週間連続
  streak30, // 1ヶ月連続
  earlyBird, // 早起き（6時前）
  totalWakeUps50, // 累計50回起床
  totalWakeUps100, // 累計100回起床
  groupMaster, // グループ作成10個
  missionMaster, // ミッション達成50回
  perfectWeek, // 完璧な1週間（毎日起床）
}

// 実績定義
class AchievementDefinition {
  final AchievementType type;
  final String title;
  final String description;
  final String icon;

  const AchievementDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<AchievementDefinition> allDefinitions = [
    AchievementDefinition(
      type: AchievementType.firstWakeUp,
      title: '目覚めの第一歩',
      description: '初めて起床ミッションを完了',
      icon: '🌅',
    ),
    AchievementDefinition(
      type: AchievementType.streak3,
      title: '3日坊主卒業',
      description: '3日連続で起床成功',
      icon: '🔥',
    ),
    AchievementDefinition(
      type: AchievementType.streak7,
      title: '1週間チャンピオン',
      description: '7日連続で起床成功',
      icon: '⭐',
    ),
    AchievementDefinition(
      type: AchievementType.streak30,
      title: '習慣マスター',
      description: '30日連続で起床成功',
      icon: '👑',
    ),
    AchievementDefinition(
      type: AchievementType.earlyBird,
      title: '早起きの鳥',
      description: '朝6時前に起床',
      icon: '🐦',
    ),
    AchievementDefinition(
      type: AchievementType.totalWakeUps50,
      title: '起床戦士',
      description: '累計50回起床成功',
      icon: '🎖️',
    ),
    AchievementDefinition(
      type: AchievementType.totalWakeUps100,
      title: '起床レジェンド',
      description: '累計100回起床成功',
      icon: '🏆',
    ),
    AchievementDefinition(
      type: AchievementType.groupMaster,
      title: 'グループリーダー',
      description: 'グループを10個作成',
      icon: '👥',
    ),
    AchievementDefinition(
      type: AchievementType.missionMaster,
      title: 'ミッション達人',
      description: 'ミッションを50回達成',
      icon: '🎯',
    ),
    AchievementDefinition(
      type: AchievementType.perfectWeek,
      title: 'パーフェクトウィーク',
      description: '1週間毎日起床成功',
      icon: '💎',
    ),
  ];

  static AchievementDefinition? getDefinition(AchievementType type) {
    try {
      return allDefinitions.firstWhere((def) => def.type == type);
    } catch (e) {
      return null;
    }
  }
}
