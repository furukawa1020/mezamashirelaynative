import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Railway デプロイ後、以下のURLを本番URLに変更してください
  // 例: static const String baseUrl = 'https://your-app.railway.app/api/v1';
  // 開発環境: localhost、本番環境: Railway URL
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // ユーザー同期
  static Future<Map<String, dynamic>> syncUser({
    required String userId,
    required String nickname,
    String? avatarUrl,
    bool isAnonymous = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'user': {
          'nickname': nickname,
          'avatar_url': avatarUrl,
          'is_anonymous': isAnonymous,
        },
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync user: ${response.body}');
    }
  }

  // ユーザー情報取得
  static Future<Map<String, dynamic>> getUser(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  // ユーザー情報更新
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? nickname,
    String? avatarUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user': {
          if (nickname != null) 'nickname': nickname,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // ユーザー統計取得
  static Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/statistics'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get statistics: ${response.body}');
    }
  }

  // グループ作成
  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required String ownerId,
    int mode = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'owner_id': ownerId, 'mode': mode}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create group: ${response.body}');
    }
  }

  // グループ参加
  static Future<Map<String, dynamic>> joinGroup({
    required String inviteCode,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'invite_code': inviteCode, 'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to join group: ${response.body}');
    }
  }

  // グループ退出
  static Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/groups/$groupId/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to leave group: ${response.body}');
    }
  }

  // グループメンバー一覧
  static Future<List<dynamic>> getGroupMembers(String groupId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['members'];
    } else {
      throw Exception('Failed to get members: ${response.body}');
    }
  }

  // ランキング取得
  static Future<List<dynamic>> getRanking({String? groupId}) async {
    final url =
        groupId != null
            ? '$baseUrl/groups/ranking?group_id=$groupId'
            : '$baseUrl/groups/ranking';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ranking'];
    } else {
      throw Exception('Failed to get ranking: ${response.body}');
    }
  }

  // メッセージ一覧取得
  static Future<List<dynamic>> getMessages({
    required String groupId,
    int limit = 50,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/messages?limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['messages'];
    } else {
      throw Exception('Failed to get messages: ${response.body}');
    }
  }

  // メッセージ作成
  static Future<Map<String, dynamic>> createMessage({
    required String groupId,
    required String content,
    required String senderUserId,
    String messageType = 'text',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': content,
        'sender_user_id': senderUserId,
        'message_type': messageType,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create message: ${response.body}');
    }
  }

  // メッセージ削除
  static Future<void> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message: ${response.body}');
    }
  }

  // リアクション追加/削除
  static Future<Map<String, dynamic>> toggleReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/$messageId/reaction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'emoji': emoji}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to toggle reaction: ${response.body}');
    }
  }
}
