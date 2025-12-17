// チャットメッセージモデル
class ChatMessage {
  final String messageId;
  final String groupId;
  final String userId;
  final String? nickname;
  final String content;
  final DateTime sentAt;
  final ChatMessageType type;
  final Map<String, dynamic>? metadata; // リアクション、添付ファイル等

  ChatMessage({
    required this.messageId,
    required this.groupId,
    required this.userId,
    this.nickname,
    required this.content,
    required this.sentAt,
    this.type = ChatMessageType.text,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'group_id': groupId,
      'user_id': userId,
      'nickname': nickname,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
      'type': type.name,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String?,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      type: ChatMessageType.values.byName(json['type'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

// メッセージタイプ
enum ChatMessageType {
  text, // テキストメッセージ
  system, // システムメッセージ（メンバー参加等）
  achievement, // 実績解除通知
  wakeUp, // 起床通知
  cheer, // 応援メッセージ
}

// リアクション
class MessageReaction {
  final String emoji;
  final String userId;
  final DateTime reactedAt;

  MessageReaction({
    required this.emoji,
    required this.userId,
    required this.reactedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'user_id': userId,
      'reacted_at': reactedAt.toIso8601String(),
    };
  }

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      userId: json['user_id'] as String,
      reactedAt: DateTime.parse(json['reacted_at'] as String),
    );
  }
}
