import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/deeplink_service.dart';
import '../models/group.dart';
import 'missions_screen.dart';
import 'groups_screen.dart';
import 'profile_screen.dart';

// 繝帙・繝逕ｻ髱｢・医Γ繧､繝ｳ繝繝・す繝･繝懊・繝会ｼ・
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
        ).showSnackBar(SnackBar(content: Text('縲・{group.name}縲阪↓蜿ょ刈縺励∪縺励◆・・)));
    
    final group = await storage.findGroupByInviteCode(inviteCode);
    
    if (group != null) {
      await storage.joinGroup(group.groupId, auth.currentUser!.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('縲・{group.name}縲阪↓蜿ょ刈縺励∪縺励◆・・)),
        );
        setState(() => _selectedIndex = 2); // 繧ｰ繝ｫ繝ｼ繝励ち繝悶↓遘ｻ蜍・
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('諡帛ｾ・さ繝ｼ繝峨′辟｡蜉ｹ縺ｧ縺・)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('諡帛ｾ・さ繝ｼ繝峨′辟｡蜉ｹ縺ｧ縺・)),
        );
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
            label: '繝帙・繝',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: '繝溘ャ繧ｷ繝ｧ繝ｳ',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: '繧ｰ繝ｫ繝ｼ繝・,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '繝励Ο繝輔ぅ繝ｼ繝ｫ',
          ),
        ],
      ),
    );
  }
}

// 繝繝・す繝･繝懊・繝峨ち繝・
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('繧√＊縺ｾ縺励Μ繝ｬ繝ｼ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 騾夂衍逕ｻ髱｢
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 繝ｦ繝ｼ繧ｶ繝ｼ諠・ｱ繧ｫ繝ｼ繝・
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
                            user?.displayName ?? '蛹ｿ蜷阪Θ繝ｼ繧ｶ繝ｼ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            user?.hasProfile ?? false
                                ? '繝励Ο繝輔ぅ繝ｼ繝ｫ險ｭ螳壽ｸ医∩'
                            user?.hasProfile ?? false 
                                ? '繝励Ο繝輔ぅ繝ｼ繝ｫ險ｭ螳壽ｸ医∩' 
                                : '繝励Ο繝輔ぅ繝ｼ繝ｫ譛ｪ險ｭ螳・,
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
                        child: const Text('險ｭ螳・),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 繧ｯ繧､繝・け繧｢繧ｯ繧ｷ繝ｧ繝ｳ
            Text('繧ｯ繧､繝・け繧｢繧ｯ繧ｷ繝ｧ繝ｳ', style: Theme.of(context).textTheme.titleMedium),
            
            // 繧ｯ繧､繝・け繧｢繧ｯ繧ｷ繝ｧ繝ｳ
            Text(
              '繧ｯ繧､繝・け繧｢繧ｯ繧ｷ繝ｧ繝ｳ',
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
                  title: '繧ｻ繝・す繝ｧ繝ｳ髢句ｧ・,
                  onTap: () {
                    // TODO: 繧ｻ繝・す繝ｧ繝ｳ髢句ｧ・
                  },
                ),
                _QuickActionCard(
                  icon: Icons.add,
                  title: '繝溘ャ繧ｷ繝ｧ繝ｳ菴懈・',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MissionsScreen()),
                      MaterialPageRoute(
                        builder: (_) => const MissionsScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.group_add,
                  title: '繧ｰ繝ｫ繝ｼ繝嶺ｽ懈・',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GroupsScreen()),
                      MaterialPageRoute(
                        builder: (_) => const GroupsScreen(),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.bluetooth,
                  title: 'BLE險ｭ螳・,
                  onTap: () {
                    // TODO: BLE險ｭ螳夂判髱｢
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 譛霑代・繧｢繧ｯ繝・ぅ繝薙ユ繧｣
            Text('譛霑代・繧｢繧ｯ繝・ぅ繝薙ユ繧｣', style: Theme.of(context).textTheme.titleMedium),
            
            // 譛霑代・繧｢繧ｯ繝・ぅ繝薙ユ繧｣
            Text(
              '譛霑代・繧｢繧ｯ繝・ぅ繝薙ユ繧｣',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('繧｢繧ｯ繝・ぅ繝薙ユ繧｣縺ｯ縺ｾ縺縺ゅｊ縺ｾ縺帙ｓ')),
                child: Center(
                  child: Text('繧｢繧ｯ繝・ぅ繝薙ユ繧｣縺ｯ縺ｾ縺縺ゅｊ縺ｾ縺帙ｓ'),
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
