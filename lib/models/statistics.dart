// 統計データ
class Statistics {
  final String userId;
  final int totalWakeUps; // 累計起床回数
  final int currentStreak; // 現在の連続記録
  final int longestStreak; // 最長連続記録
  final double successRate; // 成功率（0.0-1.0）
  final int totalMissions; // 総ミッション数
  final int completedMissions; // 完了ミッション数
  final List<DailyRecord> dailyRecords; // 日次記録
  final DateTime? lastWakeUpDate; // 最後の起床日

  Statistics({
    required this.userId,
    required this.totalWakeUps,
    required this.currentStreak,
    required this.longestStreak,
    required this.successRate,
    required this.totalMissions,
    required this.completedMissions,
    required this.dailyRecords,
    this.lastWakeUpDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_wake_ups': totalWakeUps,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'success_rate': successRate,
      'total_missions': totalMissions,
      'completed_missions': completedMissions,
      'daily_records':
          dailyRecords.map((record) => record.toJson()).toList(),
      'last_wake_up_date': lastWakeUpDate?.toIso8601String(),
    };
  }

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      userId: json['user_id'] as String,
      totalWakeUps: json['total_wake_ups'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      successRate: (json['success_rate'] as num).toDouble(),
      totalMissions: json['total_missions'] as int,
      completedMissions: json['completed_missions'] as int,
      dailyRecords: (json['daily_records'] as List)
          .map((r) => DailyRecord.fromJson(r))
          .toList(),
      lastWakeUpDate: json['last_wake_up_date'] != null
          ? DateTime.parse(json['last_wake_up_date'] as String)
          : null,
    );
  }

  // 空の統計データを生成
  factory Statistics.empty(String userId) {
    return Statistics(
      userId: userId,
      totalWakeUps: 0,
      currentStreak: 0,
      longestStreak: 0,
      successRate: 0.0,
      totalMissions: 0,
      completedMissions: 0,
      dailyRecords: [],
    );
  }
}

// 日次記録
class DailyRecord {
  final DateTime date;
  final bool wakeUpSuccess;
  final int missionsCompleted;
  final int missionsAttempted;
  final Duration? wakeUpTime; // 起床時刻（時分のみ）

  DailyRecord({
    required this.date,
    required this.wakeUpSuccess,
    required this.missionsCompleted,
    required this.missionsAttempted,
    this.wakeUpTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'wake_up_success': wakeUpSuccess,
      'missions_completed': missionsCompleted,
      'missions_attempted': missionsAttempted,
      'wake_up_time': wakeUpTime?.inMinutes,
    };
  }

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: DateTime.parse(json['date'] as String),
      wakeUpSuccess: json['wake_up_success'] as bool,
      missionsCompleted: json['missions_completed'] as int,
      missionsAttempted: json['missions_attempted'] as int,
      wakeUpTime: json['wake_up_time'] != null
          ? Duration(minutes: json['wake_up_time'] as int)
          : null,
    );
  }

  // 日付のみの比較用
  bool isSameDate(DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }
}

// 週次統計
class WeeklyStats {
  final int weekNumber;
  final int year;
  final int successDays;
  final int totalDays;
  final double averageWakeUpTime; // 平均起床時刻（分）

  WeeklyStats({
    required this.weekNumber,
    required this.year,
    required this.successDays,
    required this.totalDays,
    required this.averageWakeUpTime,
  });

  double get successRate =>
      totalDays > 0 ? successDays / totalDays : 0.0;
}

// 月次統計
class MonthlyStats {
  final int month;
  final int year;
  final int successDays;
  final int totalDays;
  final int longestStreak;

  MonthlyStats({
    required this.month,
    required this.year,
    required this.successDays,
    required this.totalDays,
    required this.longestStreak,
  });

  double get successRate =>
      totalDays > 0 ? successDays / totalDays : 0.0;
}
