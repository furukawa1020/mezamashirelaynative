import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.group)),
            title: Text('グループ招待'),
            subtitle: Text('太郎さんがあなたを「朝活グループ」に招待しました'),
            trailing: Text('2時間前'),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.check_circle)),
            title: Text('セッション完了'),
            subtitle: Text('「朝の習慣」セッションが完了しました'),
            trailing: Text('5時間前'),
          ),
          Divider(),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.celebration)),
            title: Text('ミッション達成'),
            subtitle: Text('「早起き習慣」を7日間継続達成！'),
            trailing: Text('1日前'),
          ),
        ],
      ),
    );
  }
}
