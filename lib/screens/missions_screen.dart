import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/mission.dart';
import 'mission_detail_screen.dart';

// 繝溘ャ繧ｷ繝ｧ繝ｳ邂｡逅・判髱｢
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
      builder:
          (context) => AlertDialog(
            title: const Text('繝溘ャ繧ｷ繝ｧ繝ｳ菴懈・'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '繝溘ャ繧ｷ繝ｧ繝ｳ蜷・,
                    hintText: '譛昴・繝ｫ繝ｼ繝・ぅ繝ｳ',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: '襍ｷ蠎頑凾蛻ｻ',
                    hintText: 'HH:MM',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
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
                child: const Text('菴懈・'),
              ),
            ],
          ),
      builder: (context) => AlertDialog(
        title: const Text('繝溘ャ繧ｷ繝ｧ繝ｳ菴懈・'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '繝溘ャ繧ｷ繝ｧ繝ｳ蜷・,
                hintText: '譛昴・繝ｫ繝ｼ繝・ぅ繝ｳ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: '襍ｷ蠎頑凾蛻ｻ',
                hintText: 'HH:MM',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
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
            child: const Text('菴懈・'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('繝溘ャ繧ｷ繝ｧ繝ｳ')),
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
                    const Text('繝溘ャ繧ｷ繝ｧ繝ｳ縺後≠繧翫∪縺帙ｓ'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _showCreateMissionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('繝溘ャ繧ｷ繝ｧ繝ｳ菴懈・'),
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
                      subtitle: Text('襍ｷ蠎頑凾蛻ｻ: ${mission.wakeTime}'),
                      trailing: Text('${mission.steps.length}繧ｹ繝・ャ繝・),
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
      appBar: AppBar(
        title: const Text('繝溘ャ繧ｷ繝ｧ繝ｳ'),
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
                      const Text('繝溘ャ繧ｷ繝ｧ繝ｳ縺後≠繧翫∪縺帙ｓ'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _showCreateMissionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('繝溘ャ繧ｷ繝ｧ繝ｳ菴懈・'),
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
                        subtitle: Text('襍ｷ蠎頑凾蛻ｻ: ${mission.wakeTime}'),
                        trailing: Text('${mission.steps.length}繧ｹ繝・ャ繝・),
                        onTap: () {
                          // TODO: 繝溘ャ繧ｷ繝ｧ繝ｳ隧ｳ邏ｰ逕ｻ髱｢
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMissionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
