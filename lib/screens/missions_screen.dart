import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/mission.dart';
import 'mission_detail_screen.dart';

// ミッション管理画面
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  List<Mission> _missions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    final auth = context.read<AuthService>();
    final storage = context.read<StorageService>();
<<<<<<< HEAD

=======
    
>>>>>>> 1e46074db814be4439fd1dd749b81dbe9b3dd55b
    if (auth.currentUser != null) {
      final missions = await storage.getMissions(auth.currentUser!.userId);
      setState(() {
        _missions = missions;
        _isLoading = false;
      });
    }
  }

  void _showCreateMissionDialog() {
    final nameController = TextEditingController();
    final timeController = TextEditingController(text: '07:00');

    showDialog(
      context: context,
<<<<<<< HEAD
      builder:
          (context) => AlertDialog(
            title: const Text('ミッション作成'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ミッション名',
                    hintText: '朝のルーティン',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: '起床時刻',
                    hintText: 'HH:MM',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    final auth = context.read<AuthService>();
                    final storage = context.read<StorageService>();

                    await storage.createMission(
                      userId: auth.currentUser!.userId,
                      name: nameController.text,
                      wakeTime: timeController.text,
                    );

                    Navigator.pop(context);
                    _loadMissions();
                  }
                },
                child: const Text('作成'),
              ),
            ],
          ),
=======
      builder: (context) => AlertDialog(
        title: const Text('ミッション作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ミッション名',
                hintText: '朝のルーティン',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: '起床時刻',
                hintText: 'HH:MM',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final auth = context.read<AuthService>();
                final storage = context.read<StorageService>();
                
                await storage.createMission(
                  userId: auth.currentUser!.userId,
                  name: nameController.text,
                  wakeTime: timeController.text,
                );
                
                Navigator.pop(context);
                _loadMissions();
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
>>>>>>> 1e46074db814be4439fd1dd749b81dbe9b3dd55b
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(title: const Text('ミッション')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _missions.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.task_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('ミッションがありません'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _showCreateMissionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('ミッション作成'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _missions.length,
                itemBuilder: (context, index) {
                  final mission = _missions[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(mission.name),
                      subtitle: Text('起床時刻: ${mission.wakeTime}'),
                      trailing: Text('${mission.steps.length}ステップ'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MissionDetailScreen(
                              missionId: mission.missionId,
                            ),
                          ),
                        ).then((_) => _loadMissions());
                      },
                    ),
                  );
                },
              ),
=======
      appBar: AppBar(
        title: const Text('ミッション'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _missions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('ミッションがありません'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _showCreateMissionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('ミッション作成'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _missions.length,
                  itemBuilder: (context, index) {
                    final mission = _missions[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.alarm),
                        title: Text(mission.name),
                        subtitle: Text('起床時刻: ${mission.wakeTime}'),
                        trailing: Text('${mission.steps.length}ステップ'),
                        onTap: () {
                          // TODO: ミッション詳細画面
                        },
                      ),
                    );
                  },
                ),
>>>>>>> 1e46074db814be4439fd1dd749b81dbe9b3dd55b
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMissionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
