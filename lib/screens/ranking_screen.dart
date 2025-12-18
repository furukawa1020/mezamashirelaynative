import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

// ランキング画面
class RankingScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const RankingScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<RankingEntry> _weeklyRanking = [];
  List<RankingEntry> _monthlyRanking = [];
  List<RankingEntry> _allTimeRanking = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRankings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankings() async {
    setState(() => _isLoading = true);

    try {
      // APIからランキング取得
      final ranking = await ApiService.getRanking(groupId: widget.groupId);
      
      final entries = ranking.map((r) => RankingEntry(
        userId: r['user_id'],
        nickname: r['nickname'] ?? 'ゲスト',
        score: r['success_count'] * 10,
        rank: r['rank'],
        streak: 0, // TODO: API側で計算
        avatarUrl: r['avatar_url'],
      )).toList();

      setState(() {
        _weeklyRanking = entries;
        _monthlyRanking = entries;
        _allTimeRanking = entries;
        _isLoading = false;
      });
    } catch (e) {
      // API失敗時はダミーデータ
      await Future.delayed(const Duration(seconds: 1));

      final dummyUsers = [
        RankingEntry(
          userId: '1',
          nickname: 'ユーザー1',
          score: 150,
          rank: 1,
          streak: 15,
          avatarUrl: null,
        ),
        RankingEntry(
          userId: '2',
          nickname: 'ユーザー2',
          score: 120,
          rank: 2,
          streak: 12,
          avatarUrl: null,
        ),
        RankingEntry(
          userId: '3',
          nickname: 'ユーザー3',
          score: 100,
          rank: 3,
          streak: 10,
          avatarUrl: null,
        ),
        RankingEntry(
          userId: '4',
          nickname: 'ユーザー4',
          score: 80,
          rank: 4,
          streak: 8,
        avatarUrl: null,
      ),
      RankingEntry(
        userId: '5',
        nickname: 'ユーザー5',
        score: 60,
        rank: 5,
        streak: 6,
        avatarUrl: null,
      ),
    ];

    setState(() {
      _weeklyRanking = dummyUsers;
      _monthlyRanking = dummyUsers;
      _allTimeRanking = dummyUsers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthService>().currentUser?.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} ランキング'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '週間'), Tab(text: '月間'), Tab(text: '全期間')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildRankingList(_weeklyRanking, currentUserId),
                  _buildRankingList(_monthlyRanking, currentUserId),
                  _buildRankingList(_allTimeRanking, currentUserId),
                ],
              ),
    );
  }

  Widget _buildRankingList(List<RankingEntry> rankings, String? currentUserId) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final entry = rankings[index];
        final isCurrentUser = entry.userId == currentUserId;

        return _buildRankingCard(entry, isCurrentUser, index);
      },
    );
  }

  Widget _buildRankingCard(RankingEntry entry, bool isCurrentUser, int index) {
    Color? rankColor;
    IconData? rankIcon;

    if (entry.rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (entry.rank == 2) {
      rankColor = Colors.grey[400];
      rankIcon = Icons.emoji_events;
    } else if (entry.rank == 3) {
      rankColor = Colors.brown[300];
      rankIcon = Icons.emoji_events;
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color:
            isCurrentUser
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: rankColor ?? Colors.grey[300],
                child:
                    rankIcon != null
                        ? Icon(rankIcon, color: Colors.white, size: 32)
                        : Text(
                          '${entry.rank}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.nickname,
                  style: TextStyle(
                    fontWeight:
                        isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isCurrentUser)
                Chip(
                  label: const Text('あなた', style: TextStyle(fontSize: 12)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 16,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 4),
              Text('${entry.streak}日連続'),
              const SizedBox(width: 16),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${entry.score}pt'),
            ],
          ),
          trailing:
              entry.rank <= 3
                  ? Icon(Icons.trending_up, color: rankColor, size: 32)
                  : null,
        ),
      ),
    );
  }
}

// ランキングエントリー
class RankingEntry {
  final String userId;
  final String nickname;
  final int score;
  final int rank;
  final int streak;
  final String? avatarUrl;

  RankingEntry({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.rank,
    required this.streak,
    this.avatarUrl,
  });
}
