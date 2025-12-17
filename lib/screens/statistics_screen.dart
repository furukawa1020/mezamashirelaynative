import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/statistics_service.dart';
import '../services/auth_service.dart';
import '../models/achievement.dart';

// 統計・実績画面
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final statsService = Provider.of<StatisticsService>(context, listen: false);

    if (auth.currentUser != null) {
      await statsService.loadStatistics(auth.currentUser!.userId);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('統計・実績'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '概要', icon: Icon(Icons.dashboard)),
            Tab(text: '実績', icon: Icon(Icons.emoji_events)),
            Tab(text: 'グラフ', icon: Icon(Icons.show_chart)),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: const [
                  _OverviewTab(),
                  _AchievementsTab(),
                  _ChartsTab(),
                ],
              ),
    );
  }
}

// 概要タブ
class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsService>(
      builder: (context, statsService, _) {
        final stats = statsService.statistics;

        if (stats == null) {
          return const Center(child: Text('統計データがありません'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // サマリーカード
              _buildSummaryCard(context, stats),
              const SizedBox(height: 16),

              // 詳細統計
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '累計起床',
                      '${stats.totalWakeUps}回',
                      Icons.wb_sunny,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '成功率',
                      '${(stats.successRate * 100).toStringAsFixed(1)}%',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '最長連続',
                      '${stats.longestStreak}日',
                      Icons.local_fire_department,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '総ミッション',
                      '${stats.completedMissions}/${stats.totalMissions}',
                      Icons.flag,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 最近の記録
              _buildRecentRecords(context, stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, statistics) {
    final streakColor =
        statistics.currentStreak >= 7
            ? Colors.amber
            : statistics.currentStreak >= 3
            ? Colors.orange
            : Colors.grey;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.local_fire_department, size: 64, color: streakColor),
            const SizedBox(height: 16),
            Text('現在の連続記録', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${statistics.currentStreak}日',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: streakColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (statistics.lastWakeUpDate != null)
              Text(
                '最終起床: ${_formatDate(statistics.lastWakeUpDate!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecords(BuildContext context, statistics) {
    final recentRecords = statistics.dailyRecords.reversed.take(7).toList();

    if (recentRecords.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('まだ記録がありません')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最近の記録', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...recentRecords.map((record) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      record.wakeUpSuccess ? Icons.check_circle : Icons.cancel,
                      color: record.wakeUpSuccess ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(record.date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${record.missionsCompleted}/${record.missionsAttempted} ミッション完了',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (record.wakeUpTime != null)
                      Text(
                        _formatDuration(record.wakeUpTime!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} (${_getWeekday(date.weekday)})';
  }

  String _getWeekday(int weekday) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[weekday - 1];
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
}

// 実績タブ
class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsService>(
      builder: (context, statsService, _) {
        final achievements = statsService.achievements;
        final unlockedTypes = achievements.map((a) => a.type).toSet();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: AchievementDefinition.allDefinitions.length,
          itemBuilder: (context, index) {
            final definition = AchievementDefinition.allDefinitions[index];
            final isUnlocked = unlockedTypes.contains(definition.type);
            final achievement =
                isUnlocked
                    ? achievements.firstWhere((a) => a.type == definition.type)
                    : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isUnlocked ? Colors.amber : Colors.grey[300],
                  child: Text(
                    definition.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(
                  definition.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(definition.description),
                    if (isUnlocked && achievement != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '解除日: ${_formatDate(achievement.unlockedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing:
                    isUnlocked
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.lock, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

// グラフタブ
class _ChartsTab extends StatelessWidget {
  const _ChartsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsService>(
      builder: (context, statsService, _) {
        final weeklyStats = statsService.getWeeklyStats(4);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '週次統計（最近4週間）',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...weeklyStats.map((week) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '第${week.weekNumber}週',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(week.successRate * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color:
                                    week.successRate >= 0.8
                                        ? Colors.green
                                        : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: week.successRate,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            week.successRate >= 0.8
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${week.successDays}/${week.totalDays}日成功',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (week.averageWakeUpTime > 0)
                              Text(
                                '平均 ${_formatMinutes(week.averageWakeUpTime)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatMinutes(double minutes) {
    final hours = minutes ~/ 60;
    final mins = (minutes % 60).round();
    return '$hours:${mins.toString().padLeft(2, '0')}';
  }
}
