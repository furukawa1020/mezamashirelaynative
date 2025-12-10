import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'notification_settings_screen.dart';

// プロフィール画面
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
      ).showSnackBar(const SnackBar(content: Text('プロフィールを更新しました')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('画像を選択'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: const Text('カメラで撮影'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('ギャラリーから選択'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    final image = await picker.pickImage(source: source);
    if (image != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像を選択しました: ${image.name}')));
      // TODO: 画像をStorageServiceに保存
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          if (_isEditing)
            TextButton(onPressed: _saveProfile, child: const Text('保存'))
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
            // アバター
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
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ニックネーム
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ニックネーム',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          hintText: 'ニックネームを入力',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      Text(
                        user?.displayName ?? '未設定',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ユーザーID
            Card(
              child: ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('ユーザーID'),
                subtitle: Text(
                  user?.userId ?? '',
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 登録日
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('登録日'),
                subtitle: Text(user?.createdAt.toString().split(' ')[0] ?? ''),
              ),
            ),
            const SizedBox(height: 32),

            // その他の設定
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('通知設定'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('アプリについて'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'めざましリレー',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.alarm, size: 48),
                  children: const [Text('GRAVITY式匿名アカウントシステムを採用した起床リレーアプリです')],
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'アカウントリセット',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('アカウントリセット'),
                        content: const Text('全てのデータが削除されます。この操作は取り消せません。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('キャンセル'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('リセット'),
                          ),
                        ],
                      ),
                );

                if (confirmed == true) {
                  await auth.resetAccount();
                  final storage = context.read<StorageService>();
                  await storage.clearAll();
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
