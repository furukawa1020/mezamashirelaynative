import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import 'api_service.dart';
import 'websocket_service.dart';

// チャットサービス - API連携 + WebSocket + ローカルキャッシュ
class ChatService extends ChangeNotifier {
  static const String _messagesKeyPrefix = 'mz_chat_messages';
  final Uuid _uuid = const Uuid();
  final WebSocketService _wsService = WebSocketService();

  // グループIDごとのメッセージリスト
  final Map<String, List<ChatMessage>> _messagesByGroup = {};

  ChatService() {
    // WebSocketメッセージ受信コールバック設定
    _wsService.onMessageReceived = _handleWebSocketMessage;
  }

  List<ChatMessage> getMessages(String groupId) {
    return _messagesByGroup[groupId] ?? [];
  }

  // WebSocketからのメッセージを処理
  void _handleWebSocketMessage(Map<String, dynamic> messageData) {
    try {
      final groupId = messageData['group_id'] ?? '';
      final message = ChatMessage(
        messageId: messageData['message_id'],
        groupId: groupId,
        userId: messageData['sender_user_id'],
        nickname: messageData['sender_user_id'], // TODO: ユーザー情報から取得
        content: messageData['content'],
        sentAt: DateTime.parse(messageData['created_at']),
        type: _parseMessageType(messageData['message_type']),
      );

      if (!_messagesByGroup.containsKey(groupId)) {
        _messagesByGroup[groupId] = [];
      }
      _messagesByGroup[groupId]!.add(message);
      _messagesByGroup[groupId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // ローカルキャッシュに保存
      _saveMessages(groupId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to handle WebSocket message: $e');
    }
  }

  // WebSocket接続
  Future<void> connectToGroup(String groupId) async {
    await _wsService.connect(groupId);
  }

  // WebSocket切断
  Future<void> disconnectFromGroup() async {
    await _wsService.disconnect();
  }

  // メッセージ読み込み（API連携）
  Future<void> loadMessages(String groupId) async {
    try {
      // APIからメッセージ取得
      final messages = await ApiService.getMessages(groupId: groupId);

      _messagesByGroup[groupId] =
          messages
              .map(
                (m) => ChatMessage(
                  messageId: m['message_id'],
                  groupId: groupId,
                  userId: m['sender_user_id'],
                  nickname: m['sender_user_id'], // TODO: ユーザー情報から取得
                  content: m['content'],
                  sentAt: DateTime.parse(m['created_at']),
                  type: _parseMessageType(m['message_type']),
                  metadata: {'reactions': _parseReactions(m['reactions'])},
                ),
              )
              .toList()
            ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // ローカルキャッシュに保存
      await _saveMessages(groupId);
      notifyListeners();
    } catch (e) {
      // API失敗時はローカルから読み込み
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
  }

  ChatMessageType _parseMessageType(String? type) {
    switch (type) {
      case 'system':
        return ChatMessageType.system;
      case 'wakeup':
        return ChatMessageType.wakeup;
      case 'image':
        return ChatMessageType.image;
      default:
        return ChatMessageType.text;
    }
  }

  Map<String, int> _parseReactions(Map<String, dynamic>? reactions) {
    if (reactions == null) return {};
    return reactions.map((key, value) => MapEntry(key, value as int));
  }

  // メッセージ送信（API連携）
  Future<void> sendMessage({
    required String groupId,
    required String userId,
    required String nickname,
    required String content,
    ChatMessageType type = ChatMessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // API呼び出し
      final response = await ApiService.createMessage(
        groupId: groupId,
        content: content,
        senderUserId: userId,
        messageType: type.name,
      );

      final messageData = response['message'];
      final message = ChatMessage(
        messageId: messageData['message_id'],
        groupId: groupId,
        userId: userId,
        nickname: nickname,
        content: content,
        sentAt: DateTime.parse(messageData['created_at']),
        type: type,
        metadata: metadata,
      );

      // メッセージをリストに追加
      if (!_messagesByGroup.containsKey(groupId)) {
        _messagesByGroup[groupId] = [];
      }
      _messagesByGroup[groupId]!.add(message);

      // ローカルキャッシュに保存
      await _saveMessages(groupId);
      notifyListeners();
    } catch (e) {
      // API失敗時はローカルのみで処理
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

      if (!_messagesByGroup.containsKey(groupId)) {
        _messagesByGroup[groupId] = [];
      }
      _messagesByGroup[groupId]!.add(message);

      await _saveMessages(groupId);
      notifyListeners();
    }
  }

  // システムメッセージを送信（メンバー参加等）
  Future<void> sendSystemMessage(String groupId, String content) async {
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

    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
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
