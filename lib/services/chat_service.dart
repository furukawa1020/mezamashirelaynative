import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

// チャットサービス
class ChatService extends ChangeNotifier {
  static const String _messagesKeyPrefix = 'mz_chat_messages';
  final Uuid _uuid = const Uuid();

  // グループIDごとのメッセージリスト
  final Map<String, List<ChatMessage>> _messagesByGroup = {};

  List<ChatMessage> getMessages(String groupId) {
    return _messagesByGroup[groupId] ?? [];
  }

  // メッセージ読み込み
  Future<void> loadMessages(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesStr = prefs.getString('$_messagesKeyPrefix\_$groupId');
    
    if (messagesStr != null) {
      final List<dynamic> messagesJson = jsonDecode(messagesStr);
      _messagesByGroup[groupId] =
          messagesJson.map((j) => ChatMessage.fromJson(j)).toList()
            ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      notifyListeners();
    }
  }

  // メッセージ送信
  Future<void> sendMessage({
    required String groupId,
    required String userId,
    required String nickname,
    required String content,
    ChatMessageType type = ChatMessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final message = ChatMessage(
      messageId: _uuid.v4(),
      groupId: groupId,
      userId: userId,
      nickname: nickname,
      content: content,
      sentAt: DateTime.now(),
      type: type,
      metadata: metadata,
    );

    // メッセージをリストに追加
    if (!_messagesByGroup.containsKey(groupId)) {
      _messagesByGroup[groupId] = [];
    }
    _messagesByGroup[groupId]!.add(message);

    // 保存
    await _saveMessages(groupId);
    notifyListeners();
  }

  // システムメッセージを送信（メンバー参加等）
  Future<void> sendSystemMessage(
    String groupId,
    String content,
  ) async {
    await sendMessage(
      groupId: groupId,
      userId: 'system',
      nickname: 'システム',
      content: content,
      type: ChatMessageType.system,
    );
  }

  // 起床通知メッセージ
  Future<void> sendWakeUpMessage(
    String groupId,
    String userId,
    String nickname,
  ) async {
    await sendMessage(
      groupId: groupId,
      userId: userId,
      nickname: nickname,
      content: '起床しました！ 🌅',
      type: ChatMessageType.wakeUp,
    );
  }

  // 実績解除メッセージ
  Future<void> sendAchievementMessage(
    String groupId,
    String userId,
    String nickname,
    String achievementTitle,
  ) async {
    await sendMessage(
      groupId: groupId,
      userId: userId,
      nickname: nickname,
      content: '実績「$achievementTitle」を解除しました！ 🏆',
      type: ChatMessageType.achievement,
    );
  }

  // 応援メッセージを送信
  Future<void> sendCheerMessage(
    String groupId,
    String userId,
    String nickname,
    String targetNickname,
  ) async {
    await sendMessage(
      groupId: groupId,
      userId: userId,
      nickname: nickname,
      content: '$targetNicknameさん、頑張って！ 💪',
      type: ChatMessageType.cheer,
    );
  }

  // リアクションを追加
  Future<void> addReaction(
    String groupId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    final messages = _messagesByGroup[groupId];
    if (messages == null) return;

    final messageIndex =
        messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex == -1) return;

    final message = messages[messageIndex];
    final metadata = message.metadata ?? {};
    final reactions = metadata['reactions'] as List? ?? [];

    // 既に同じ絵文字でリアクション済みか確認
    final existingIndex = reactions.indexWhere(
      (r) => r['emoji'] == emoji && r['user_id'] == userId,
    );

    if (existingIndex >= 0) {
      // 既存のリアクションを削除（トグル動作）
      reactions.removeAt(existingIndex);
    } else {
      // 新しいリアクションを追加
      reactions.add({
        'emoji': emoji,
        'user_id': userId,
        'reacted_at': DateTime.now().toIso8601String(),
      });
    }

    metadata['reactions'] = reactions;

    // メッセージを更新
    final updatedMessage = ChatMessage(
      messageId: message.messageId,
      groupId: message.groupId,
      userId: message.userId,
      nickname: message.nickname,
      content: message.content,
      sentAt: message.sentAt,
      type: message.type,
      metadata: metadata,
    );

    messages[messageIndex] = updatedMessage;
    await _saveMessages(groupId);
    notifyListeners();
  }

  // メッセージを保存
  Future<void> _saveMessages(String groupId) async {
    final messages = _messagesByGroup[groupId];
    if (messages == null) return;

    final prefs = await SharedPreferences.getInstance();
    final messagesJson = messages.map((m) => m.toJson()).toList();
    await prefs.setString(
      '$_messagesKeyPrefix\_$groupId',
      jsonEncode(messagesJson),
    );
  }

  // メッセージを削除
  Future<void> deleteMessage(String groupId, String messageId) async {
    final messages = _messagesByGroup[groupId];
    if (messages == null) return;

    messages.removeWhere((m) => m.messageId == messageId);
    await _saveMessages(groupId);
    notifyListeners();
  }

  // グループのメッセージを全削除
  Future<void> clearMessages(String groupId) async {
    _messagesByGroup[groupId] = [];
    await _saveMessages(groupId);
    notifyListeners();
  }
}
