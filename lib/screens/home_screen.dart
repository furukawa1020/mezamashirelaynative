import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/deeplink_service.dart';
import '../models/group.dart';
import 'missions_screen.dart';
import 'groups_screen.dart';
import 'profile_screen.dart';

// ホーム画面（メインダッシュボード）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const MissionsScreen(),
    const GroupsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _setupDeeplink();
  }

  void _setupDeeplink() {
    final deeplinkService = context.read<DeeplinkService>();
    deeplinkService.onInviteCodeReceived = (inviteCode) {
      _handleInviteCode(inviteCode);
    };
  }

  Future<void> _handleInviteCode(String inviteCode) async {
    final storage = context.read<StorageService>();
    final auth = context.read<AuthService>();

    final group = await storage.findGroupByInviteCode(inviteCode);

    if (group != null) {
      await storage.joinGroup(group.groupId, auth.currentUser!.userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('「${group.name}」に参加しました！')));
        setState(() => _selectedIndex = 2); // グループタブに移動
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('招待コードが無効です')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'ミッション',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'グループ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}

// ダッシュボードタブ
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('めざましリレー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 通知画面
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ユーザー情報カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Text(
                        user?.displayName[0] ?? '?',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? '匿名ユーザー',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            user?.hasProfile ?? false
                                ? 'プロフィール設定済み'
                                : 'プロフィール未設定',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (!(user?.hasProfile ?? false))
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: const Text('設定'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // クイックアクション
            Text('クイックアクション', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _QuickActionCard(
                  icon: Icons.play_arrow,
                  title: 'セッション開始',
                  onTap: () {
                    // TODO: セッション開始
                  },
                ),
                _QuickActionCard(
                  icon: Icons.add,
                  title: 'ミッション作成',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MissionsScreen()),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.group_add,
                  title: 'グループ作成',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GroupsScreen()),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.bluetooth,
                  title: 'BLE設定',
                  onTap: () {
                    // TODO: BLE設定画面
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 最近のアクティビティ
            Text('最近のアクティビティ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('アクティビティはまだありません')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
