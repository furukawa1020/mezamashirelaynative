import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionReminders = prefs.getBool('notif_session_reminders') ?? true;
      _groupInvitations = prefs.getBool('notif_group_invitations') ?? true;
      _achievementNotifications = prefs.getBool('notif_achievements') ?? true;
      _bleConnectionAlerts = prefs.getBool('notif_ble_alerts') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_session_reminders', _sessionReminders);
    await prefs.setBool('notif_group_invitations', _groupInvitations);
    await prefs.setBool('notif_achievements', _achievementNotifications);
    await prefs.setBool('notif_ble_alerts', _bleConnectionAlerts);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('通知設定を保存しました')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('通知設定')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'その他',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('通知について'),
            subtitle: const Text('ローカル通知のみ使用しています'),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _saveSettings,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
