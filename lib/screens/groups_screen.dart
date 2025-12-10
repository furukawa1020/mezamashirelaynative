import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../models/group.dart';

// 繧ｰ繝ｫ繝ｼ繝礼ｮ｡逅・判髱｢
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
                  title: const Text('繧ｰ繝ｫ繝ｼ繝嶺ｽ懈・'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '繧ｰ繝ｫ繝ｼ繝怜錐',
                          hintText: '譛晄ｴｻ繧ｰ繝ｫ繝ｼ繝・,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<GroupMode>(
                        segments: const [
                          ButtonSegment(
                            value: GroupMode.race,
                            label: Text('遶ｶ莠峨Δ繝ｼ繝・),
                            icon: Icon(Icons.speed),
                          ),
                          ButtonSegment(
                            value: GroupMode.all,
                            label: Text('蜈ｨ蜩｡繝｢繝ｼ繝・),
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
                      child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
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
                      child: const Text('菴懈・'),
                    ),
                  ],
                ),
          ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('繧ｰ繝ｫ繝ｼ繝嶺ｽ懈・'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '繧ｰ繝ｫ繝ｼ繝怜錐',
                  hintText: '譛晄ｴｻ繧ｰ繝ｫ繝ｼ繝・,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<GroupMode>(
                segments: const [
                  ButtonSegment(
                    value: GroupMode.race,
                    label: Text('遶ｶ莠峨Δ繝ｼ繝・),
                    icon: Icon(Icons.speed),
                  ),
                  ButtonSegment(
                    value: GroupMode.all,
                    label: Text('蜈ｨ蜩｡繝｢繝ｼ繝・),
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
              child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
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
              child: const Text('菴懈・'),
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
            title: const Text('繧ｰ繝ｫ繝ｼ繝怜盾蜉'),
            content: TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: '諡帛ｾ・さ繝ｼ繝・,
                hintText: 'ABC123',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
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
                        SnackBar(content: Text('縲・{group.name}縲阪↓蜿ょ刈縺励∪縺励◆')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('諡帛ｾ・さ繝ｼ繝峨′辟｡蜉ｹ縺ｧ縺・)),
                      );
                    }
                  }
                },
                child: const Text('蜿ょ刈'),
              ),
            ],
          ),
      builder: (context) => AlertDialog(
        title: const Text('繧ｰ繝ｫ繝ｼ繝怜盾蜉'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: '諡帛ｾ・さ繝ｼ繝・,
            hintText: 'ABC123',
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.toUpperCase();
              if (code.length == 6) {
                final auth = context.read<AuthService>();
                final storage = context.read<StorageService>();
                
                final group = await storage.findGroupByInviteCode(code);
                if (group != null) {
                  await storage.joinGroup(group.groupId, auth.currentUser!.userId);
                  Navigator.pop(context);
                  _loadGroups();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('縲・{group.name}縲阪↓蜿ょ刈縺励∪縺励◆')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('諡帛ｾ・さ繝ｼ繝峨′辟｡蜉ｹ縺ｧ縺・)),
                  );
                }
              }
            },
            child: const Text('蜿ょ刈'),
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
                    '繧ｰ繝ｫ繝ｼ繝励ｒ蜈ｱ譛・,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // QR繧ｳ繝ｼ繝・
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

                  // 諡帛ｾ・さ繝ｼ繝・
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('諡帛ｾ・さ繝ｼ繝・),
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
                            const SnackBar(content: Text('繧ｳ繝斐・縺励∪縺励◆')),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SNS蜈ｱ譛峨・繧ｿ繝ｳ
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _ShareButton(
                        icon: Icons.share,
                        label: '蜈ｱ譛・,
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
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '繧ｰ繝ｫ繝ｼ繝励ｒ蜈ｱ譛・,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // QR繧ｳ繝ｼ繝・
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
              
              // 諡帛ｾ・さ繝ｼ繝・
              Card(
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('諡帛ｾ・さ繝ｼ繝・),
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
                      Clipboard.setData(ClipboardData(text: group.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('繧ｳ繝斐・縺励∪縺励◆')),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // SNS蜈ｱ譛峨・繧ｿ繝ｳ
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _ShareButton(
                    icon: Icons.share,
                    label: '蜈ｱ譛・,
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
        title: const Text('繧ｰ繝ｫ繝ｼ繝・),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _showJoinGroupDialog,
            tooltip: '繧ｰ繝ｫ繝ｼ繝励↓蜿ょ刈',
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
                    const Text('繧ｰ繝ｫ繝ｼ繝励′縺ゅｊ縺ｾ縺帙ｓ'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _showCreateGroupDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('繧ｰ繝ｫ繝ｼ繝嶺ｽ懈・'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showJoinGroupDialog,
                      icon: const Icon(Icons.login),
                      label: const Text('諡帛ｾ・さ繝ｼ繝峨〒蜿ょ刈'),
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
                        '${group.memberIds.length}莠ｺ ﾂｷ ${group.mode == GroupMode.race ? "遶ｶ莠峨Δ繝ｼ繝・ : "蜈ｨ蜩｡繝｢繝ｼ繝・}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _showShareDialog(group),
                      ),
                    ),
                  );
                },
              ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('繧ｰ繝ｫ繝ｼ繝励′縺ゅｊ縺ｾ縺帙ｓ'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _showCreateGroupDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('繧ｰ繝ｫ繝ｼ繝嶺ｽ懈・'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showJoinGroupDialog,
                        icon: const Icon(Icons.login),
                        label: const Text('諡帛ｾ・さ繝ｼ繝峨〒蜿ょ刈'),
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
                          group.mode == GroupMode.race ? Icons.speed : Icons.group,
                        ),
                        title: Text(group.name),
                        subtitle: Text(
                          '${group.memberIds.length}莠ｺ ﾂｷ ${group.mode == GroupMode.race ? "遶ｶ莠峨Δ繝ｼ繝・ : "蜈ｨ蜩｡繝｢繝ｼ繝・}',
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
      style: color != null
          ? FilledButton.styleFrom(backgroundColor: color)
          : null,
    );
  }
}
