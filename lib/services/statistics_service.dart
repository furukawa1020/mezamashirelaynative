import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/statistics.dart';
import '../models/achievement.dart';
import '../models/session.dart';

// 統計サービス
class StatisticsService extends ChangeNotifier {
  static const String _statisticsKey = 'mz_statistics';
  static const String _achievementsKey = 'mz_achievements';

  Statistics? _statistics;
  List<Achievement> _achievements = [];

  Statistics? get statistics => _statistics;
  List<Achievement> get achievements => _achievements;

  // 統計データを読み込み
  Future<void> loadStatistics(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // 統計データ
    final statsStr = prefs.getString('$_statisticsKey\_$userId');
    if (statsStr != null) {
      _statistics = Statistics.fromJson(jsonDecode(statsStr));
    } else {
      _statistics = Statistics.empty(userId);
    }

    // 実績データ
    final achievementsStr = prefs.getString('$_achievementsKey\_$userId');
    if (achievementsStr != null) {
      final List<dynamic> achievementsJson = jsonDecode(achievementsStr);
      _achievements =
          achievementsJson.map((j) => Achievement.fromJson(j)).toList();
    }

    notifyListeners();
  }

  // セッション完了時に統計を更新
  Future<void> updateStatisticsFromSession(
    String userId,
    Session session,
  ) async {
    if (_statistics == null) {
      await loadStatistics(userId);
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // セッションが成功したか判定
    final success = session.status == SessionStatus.completed;

    // 日次記録を更新
    final existingRecordIndex = _statistics!.dailyRecords.indexWhere(
      (record) => record.isSameDate(todayDate),
    );

    if (existingRecordIndex >= 0) {
      // 既存の記録を更新
      final existingRecord = _statistics!.dailyRecords[existingRecordIndex];
      final updatedRecord = DailyRecord(
        date: todayDate,
        wakeUpSuccess: existingRecord.wakeUpSuccess || success,
        missionsCompleted: existingRecord.missionsCompleted + (success ? 1 : 0),
        missionsAttempted: existingRecord.missionsAttempted + 1,
        wakeUpTime:
            success
                ? Duration(hours: now.hour, minutes: now.minute)
                : existingRecord.wakeUpTime,
      );
      _statistics!.dailyRecords[existingRecordIndex] = updatedRecord;
    } else {
      // 新規記録を追加
      _statistics!.dailyRecords.add(
        DailyRecord(
          date: todayDate,
          wakeUpSuccess: success,
          missionsCompleted: success ? 1 : 0,
          missionsAttempted: 1,
          wakeUpTime:
              success ? Duration(hours: now.hour, minutes: now.minute) : null,
        ),
      );
    }

    // 統計値を再計算
    _recalculateStatistics(userId);

    // 実績チェック
    await _checkAndUnlockAchievements(userId);

    // 保存
    await _saveStatistics(userId);
    notifyListeners();
  }

  // 統計値を再計算
  void _recalculateStatistics(String userId) {
    if (_statistics == null) return;

    // 日次記録をソート
    _statistics!.dailyRecords.sort((a, b) => a.date.compareTo(b.date));

    // 総起床回数
    final totalWakeUps =
        _statistics!.dailyRecords
            .where((record) => record.wakeUpSuccess)
            .length;

    // 総ミッション数と完了数
    final totalMissions = _statistics!.dailyRecords.fold(
      0,
      (sum, r) => sum + r.missionsAttempted,
    );
    final completedMissions = _statistics!.dailyRecords.fold(
      0,
      (sum, r) => sum + r.missionsCompleted,
    );

    // 成功率
    final successRate =
        totalMissions > 0 ? completedMissions / totalMissions : 0.0;

    // 連続記録を計算
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = _statistics!.dailyRecords.length - 1; i >= 0; i--) {
      final record = _statistics!.dailyRecords[i];

      if (record.wakeUpSuccess) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }

        // 最新の連続記録を計算
        final daysDiff = today.difference(record.date).inDays;
        if (daysDiff == currentStreak) {
          currentStreak++;
        }
      } else {
        tempStreak = 0;
        // 今日でない場合は連続記録リセット
        if (!record.isSameDate(today)) {
          break;
        }
      }
    }

    // 最後の起床日
    DateTime? lastWakeUpDate;
    for (int i = _statistics!.dailyRecords.length - 1; i >= 0; i--) {
      if (_statistics!.dailyRecords[i].wakeUpSuccess) {
        lastWakeUpDate = _statistics!.dailyRecords[i].date;
        break;
      }
    }

    // 統計オブジェクトを更新
    _statistics = Statistics(
      userId: userId,
      totalWakeUps: totalWakeUps,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      successRate: successRate,
      totalMissions: totalMissions,
      completedMissions: completedMissions,
      dailyRecords: _statistics!.dailyRecords,
      lastWakeUpDate: lastWakeUpDate,
    );
  }

  // 実績チェックと解除
  Future<void> _checkAndUnlockAchievements(String userId) async {
    if (_statistics == null) return;

    final newAchievements = <Achievement>[];

    // 既に解除済みの実績タイプを取得
    final unlockedTypes = _achievements.map((a) => a.type).toSet();

    // 初めての起床
    if (_statistics!.totalWakeUps >= 1 &&
        !unlockedTypes.contains(AchievementType.firstWakeUp)) {
      newAchievements.add(
        _createAchievement(
          userId,
          AchievementType.firstWakeUp,
          _statistics!.totalWakeUps,
        ),
      );
    }

    // 連続記録
    if (_statistics!.currentStreak >= 3 &&
        !unlockedTypes.contains(AchievementType.streak3)) {
      newAchievements.add(
        _createAchievement(
          userId,
          AchievementType.streak3,
          _statistics!.currentStreak,
        ),
      );
    }

    if (_statistics!.currentStreak >= 7 &&
        !unlockedTypes.contains(AchievementType.streak7)) {
      newAchievements.add(
        _createAchievement(
          userId,
          AchievementType.streak7,
          _statistics!.currentStreak,
        ),
      );
    }

    if (_statistics!.currentStreak >= 30 &&
        !unlockedTypes.contains(AchievementType.streak30)) {
      newAchievements.add(
        _createAchievement(
          userId,
          AchievementType.streak30,
          _statistics!.currentStreak,
        ),
      );
    }

    // 累計起床回数
    if (_statistics!.totalWakeUps >= 50 &&
        !unlockedTypes.contains(AchievementType.totalWakeUps50)) {
      newAchievements.add(
        _createAchievement(
          userId,
          AchievementType.totalWakeUps50,
          _statistics!.totalWakeUps,
        ),
      );
    }

    if (_statistics!.totalWakeUps >= 100 &&
        !unlockedTypes.contains(AchievementType.totalWakeUps100)) {
      newAchievements.add(
        _createAchievement(
          userId,
          AchievementType.totalWakeUps100,
          _statistics!.totalWakeUps,
        ),
      );
    }

    // ミッション達成数
    if (_statistics!.completedMissions >= 50 &&
        !unlockedTypes.contains(AchievementType.missionMaster)) {
      newAchievements.add(
        _createAchievement(
          userId,
          AchievementType.missionMaster,
          _statistics!.completedMissions,
        ),
      );
    }

    // 早起き（6時前）
    final todayRecord = _statistics!.dailyRecords.lastWhere(
      (r) => r.isSameDate(DateTime.now()),
      orElse:
          () => DailyRecord(
            date: DateTime.now(),
            wakeUpSuccess: false,
            missionsCompleted: 0,
            missionsAttempted: 0,
          ),
    );

    if (todayRecord.wakeUpTime != null &&
        todayRecord.wakeUpTime!.inMinutes < 360 &&
        !unlockedTypes.contains(AchievementType.earlyBird)) {
      newAchievements.add(
        _createAchievement(
          userId,
          AchievementType.earlyBird,
          todayRecord.wakeUpTime!.inMinutes,
        ),
      );
    }

    // 新規実績を追加
    _achievements.addAll(newAchievements);

    // 実績保存
    await _saveAchievements(userId);
  }

  // 実績オブジェクトを作成
  Achievement _createAchievement(
    String userId,
    AchievementType type,
    int value,
  ) {
    final definition = AchievementDefinition.getDefinition(type)!;
    return Achievement(
      achievementId: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      title: definition.title,
      description: definition.description,
      unlockedAt: DateTime.now(),
      value: value,
    );
  }

  // 統計保存
  Future<void> _saveStatistics(String userId) async {
    if (_statistics == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_statisticsKey\_$userId',
      jsonEncode(_statistics!.toJson()),
    );
  }

  // 実績保存
  Future<void> _saveAchievements(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = _achievements.map((a) => a.toJson()).toList();
    await prefs.setString(
      '$_achievementsKey\_$userId',
      jsonEncode(achievementsJson),
    );
  }

  // 週次統計を計算
  List<WeeklyStats> getWeeklyStats(int weeks) {
    if (_statistics == null) return [];

    final now = DateTime.now();
    final weeklyStats = <WeeklyStats>[];

    for (int i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weekRecords =
          _statistics!.dailyRecords.where((record) {
            return record.date.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                record.date.isBefore(weekEnd.add(const Duration(days: 1)));
          }).toList();

      final successDays = weekRecords.where((r) => r.wakeUpSuccess).length;
      final totalDays = weekRecords.length;

      final wakeUpTimes =
          weekRecords
              .where((r) => r.wakeUpTime != null)
              .map((r) => r.wakeUpTime!.inMinutes)
              .toList();

      final averageWakeUpTime =
          wakeUpTimes.isNotEmpty
              ? wakeUpTimes.reduce((a, b) => a + b) / wakeUpTimes.length
              : 0.0;

      weeklyStats.add(
        WeeklyStats(
          weekNumber: _getWeekNumber(weekStart),
          year: weekStart.year,
          successDays: successDays,
          totalDays: totalDays,
          averageWakeUpTime: averageWakeUpTime,
        ),
      );
    }

    return weeklyStats.reversed.toList();
  }

  // 週番号を取得
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return (daysDifference / 7).ceil() + 1;
  }
}
