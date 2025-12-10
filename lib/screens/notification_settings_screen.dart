import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _sessionReminders = true;
  bool _groupInvitations = true;
  bool _achievementNotifications = true;
  bool _bleConnectionAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知設定')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '通知の種類',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('セッションリマインダー'),
            subtitle: const Text('セッション開始時刻の通知'),
            value: _sessionReminders,
            onChanged: (value) {
              setState(() => _sessionReminders = value);
            },
          ),
          SwitchListTile(
            title: const Text('グループ招待'),
            subtitle: const Text('新しいグループ招待の通知'),
            value: _groupInvitations,
            onChanged: (value) {
              setState(() => _groupInvitations = value);
            },
          ),
          SwitchListTile(
            title: const Text('達成通知'),
            subtitle: const Text('ミッション達成時の通知'),
            value: _achievementNotifications,
            onChanged: (value) {
              setState(() => _achievementNotifications = value);
            },
          ),
          SwitchListTile(
            title: const Text('BLE接続アラート'),
            subtitle: const Text('デバイス接続状態の通知'),
            value: _bleConnectionAlerts,
            onChanged: (value) {
              setState(() => _bleConnectionAlerts = value);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('通知設定を保存しました')));
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
