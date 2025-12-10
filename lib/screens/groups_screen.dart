import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../models/group.dart';

// グループ管理画面
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final auth = context.read<AuthService>();
    final storage = context.read<StorageService>();

    if (auth.currentUser != null) {
      final groups = await storage.getGroups(auth.currentUser!.userId);
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    GroupMode selectedMode = GroupMode.race;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('グループ作成'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'グループ名',
                          hintText: '朝活グループ',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<GroupMode>(
                        segments: const [
                          ButtonSegment(
                            value: GroupMode.race,
                            label: Text('競争モード'),
                            icon: Icon(Icons.speed),
                          ),
                          ButtonSegment(
                            value: GroupMode.all,
                            label: Text('全員モード'),
                            icon: Icon(Icons.group),
                          ),
                        ],
                        selected: {selectedMode},
                        onSelectionChanged: (Set<GroupMode> newSelection) {
                          setDialogState(() {
                            selectedMode = newSelection.first;
                          });
                        },
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

                          await storage.createGroup(
                            name: nameController.text,
                            mode: selectedMode,
                            ownerId: auth.currentUser!.userId,
                          );

                          Navigator.pop(context);
                          _loadGroups();
                        }
                      },
                      child: const Text('作成'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('グループ参加'),
            content: TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: '招待コード',
                hintText: 'ABC123',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () async {
                  final code = codeController.text.toUpperCase();
                  if (code.length == 6) {
                    final auth = context.read<AuthService>();
                    final storage = context.read<StorageService>();

                    final group = await storage.findGroupByInviteCode(code);
                    if (group != null) {
                      await storage.joinGroup(
                        group.groupId,
                        auth.currentUser!.userId,
                      );
                      Navigator.pop(context);
                      _loadGroups();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('「${group.name}」に参加しました')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('招待コードが無効です')),
                      );
                    }
                  }
                },
                child: const Text('参加'),
              ),
            ],
          ),
    );
  }

  void _showShareDialog(Group group) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'グループを共有',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // QRコード
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: group.deepLink,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 招待コード
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('招待コード'),
                      subtitle: Text(
                        group.inviteCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: group.inviteCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('コピーしました')),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SNS共有ボタン
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _ShareButton(
                        icon: Icons.share,
                        label: '共有',
                        onPressed: () => ShareService.shareGroup(group),
                      ),
                      _ShareButton(
                        icon: Icons.chat,
                        label: 'LINE',
                        color: Colors.green,
                        onPressed: () => ShareService.shareToLine(group),
                      ),
                      _ShareButton(
                        icon: Icons.flutter_dash,
                        label: 'X',
                        color: Colors.black,
                        onPressed: () => ShareService.shareToX(group),
                      ),
                      _ShareButton(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        color: Colors.blue,
                        onPressed: () => ShareService.shareToFacebook(group),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _showJoinGroupDialog,
            tooltip: 'グループに参加',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _groups.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('グループがありません'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _showCreateGroupDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('グループ作成'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showJoinGroupDialog,
                      icon: const Icon(Icons.login),
                      label: const Text('招待コードで参加'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        group.mode == GroupMode.race
                            ? Icons.speed
                            : Icons.group,
                      ),
                      title: Text(group.name),
                      subtitle: Text(
                        '${group.memberIds.length}人 · ${group.mode == GroupMode.race ? "競争モード" : "全員モード"}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _showShareDialog(group),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const _ShareButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style:
          color != null ? FilledButton.styleFrom(backgroundColor: color) : null,
    );
  }
}
