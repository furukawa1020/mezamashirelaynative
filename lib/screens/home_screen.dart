import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/ble_service.dart';
import 'missions_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'session_screen.dart';

// ホーム画面（メインダッシュボード）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const MissionsScreen(),
    const Center(child: Text('グループ画面（未実装）')),
    const ProfileScreen(),
  ];

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
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Future<void> _startQuickSession() async {
    final storage = context.read<StorageService>();
    final auth = context.read<AuthService>();
    
    // グループとミッションを取得
    final groups = await storage.getGroups(auth.currentUser!.userId);
    final missions = await storage.getMissions(auth.currentUser!.userId);
    
    if (groups.isEmpty || missions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先にグループとミッションを作成してください')),
      );
      return;
    }
    
    // 最初のグループとミッションでセッション開始
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionScreen(
          groupId: groups.first.groupId,
          missionId: missions.first.missionId,
        ),
      ),
    );
  }

  Future<void> _showBLESettings() async {
    final bleService = BLEService();
    
    final isAvailable = await bleService.isAvailable();
    
    if (!mounted) return;
    
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetoothが利用できません')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      builder: (context) => const _BLESettingsSheet(),
    );
  }

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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
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
            Text(
              'クイックアクション',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
                  onTap: _startQuickSession,
                ),
                _QuickActionCard(
                  icon: Icons.add,
                  title: 'ミッション作成',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MissionsScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.group_add,
                  title: 'グループ作成',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GroupsScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.bluetooth,
                  title: 'BLE設定',
                  onTap: _showBLESettings,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 最近のアクティビティ
            Text(
              '最近のアクティビティ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('アクティビティはまだありません'),
                ),
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

// BLE設定シート
class _BLESettingsSheet extends StatefulWidget {
  const _BLESettingsSheet();

  @override
  State<_BLESettingsSheet> createState() => _BLESettingsSheetState();
}

class _BLESettingsSheetState extends State<_BLESettingsSheet> {
  final BLEService _bleService = BLEService();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
    });
    await _bleService.startScan();
  }

  @override
  void dispose() {
    _bleService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'BLEデバイス',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isScanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: StreamBuilder(
              stream: _bleService.scanResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('デバイスが見つかりません'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final result = snapshot.data![index];
                    return ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(result.device.platformName.isEmpty
                          ? '不明なデバイス'
                          : result.device.platformName),
                      subtitle: Text(result.device.remoteId.toString()),
                      trailing: Text('${result.rssi} dBm'),
                      onTap: () async {
                        await _bleService.connectDevice(result.device);
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${result.device.platformName}に接続しました',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
