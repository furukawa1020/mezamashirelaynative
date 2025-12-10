import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// 繝励Ο繝輔ぅ繝ｼ繝ｫ逕ｻ髱｢
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nicknameController.text = user?.nickname ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthService>();
    await auth.updateProfile(nickname: _nicknameController.text);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('繝励Ο繝輔ぅ繝ｼ繝ｫ繧呈峩譁ｰ縺励∪縺励◆')));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('繝励Ο繝輔ぅ繝ｼ繝ｫ繧呈峩譁ｰ縺励∪縺励◆')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('繝励Ο繝輔ぅ繝ｼ繝ｫ'),
        actions: [
          if (_isEditing)
            TextButton(onPressed: _saveProfile, child: const Text('菫晏ｭ・))
            TextButton(
              onPressed: _saveProfile,
              child: const Text('菫晏ｭ・),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 繧｢繝舌ち繝ｼ
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    child: Text(
                      user?.displayName[0] ?? '?',
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: () {
                            // TODO: 逕ｻ蜒城∈謚・
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            
            // 繝九ャ繧ｯ繝阪・繝
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '繝九ャ繧ｯ繝阪・繝',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          hintText: '繝九ャ繧ｯ繝阪・繝繧貞・蜉・,
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      Text(
                        user?.displayName ?? '譛ｪ險ｭ螳・,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            
            // 繝ｦ繝ｼ繧ｶ繝ｼID
            Card(
              child: ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('繝ｦ繝ｼ繧ｶ繝ｼID'),
                subtitle: Text(
                  user?.userId ?? '',
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 16),

            
            // 逋ｻ骭ｲ譌･
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('逋ｻ骭ｲ譌･'),
                subtitle: Text(user?.createdAt.toString().split(' ')[0] ?? ''),
              ),
            ),
            const SizedBox(height: 32),

                subtitle: Text(
                  user?.createdAt.toString().split(' ')[0] ?? '',
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 縺昴・莉悶・險ｭ螳・
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('騾夂衍險ｭ螳・),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 騾夂衍險ｭ螳夂判髱｢
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('繧｢繝励Μ縺ｫ縺､縺・※'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: '繧√＊縺ｾ縺励Μ繝ｬ繝ｼ',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.alarm, size: 48),
                  children: const [Text('GRAVITY蠑丞諺蜷阪い繧ｫ繧ｦ繝ｳ繝医す繧ｹ繝・Β繧呈治逕ｨ縺励◆襍ｷ蠎翫Μ繝ｬ繝ｼ繧｢繝励Μ縺ｧ縺吶・)],
                  children: const [
                    Text('GRAVITY蠑丞諺蜷阪い繧ｫ繧ｦ繝ｳ繝医す繧ｹ繝・Β繧呈治逕ｨ縺励◆襍ｷ蠎翫Μ繝ｬ繝ｼ繧｢繝励Μ縺ｧ縺吶・),
                  ],
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                '繧｢繧ｫ繧ｦ繝ｳ繝医Μ繧ｻ繝・ヨ',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('繧｢繧ｫ繧ｦ繝ｳ繝医Μ繧ｻ繝・ヨ'),
                        content: const Text('蜈ｨ縺ｦ縺ｮ繝・・繧ｿ縺悟炎髯､縺輔ｌ縺ｾ縺吶ゅ％縺ｮ謫堺ｽ懊・蜿悶ｊ豸医○縺ｾ縺帙ｓ縲・),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('繝ｪ繧ｻ繝・ヨ'),
                          ),
                        ],
                      ),
                );

              title: const Text('繧｢繧ｫ繧ｦ繝ｳ繝医Μ繧ｻ繝・ヨ', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('繧｢繧ｫ繧ｦ繝ｳ繝医Μ繧ｻ繝・ヨ'),
                    content: const Text('蜈ｨ縺ｦ縺ｮ繝・・繧ｿ縺悟炎髯､縺輔ｌ縺ｾ縺吶ゅ％縺ｮ謫堺ｽ懊・蜿悶ｊ豸医○縺ｾ縺帙ｓ縲・),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('繧ｭ繝｣繝ｳ繧ｻ繝ｫ'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('繝ｪ繧ｻ繝・ヨ'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  await auth.resetAccount();
                  await context.read<StorageService>().clearAll();
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
