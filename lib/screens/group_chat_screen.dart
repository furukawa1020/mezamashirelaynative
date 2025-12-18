import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/chat_message.dart';
import '../models/group.dart';

// グループチャット画面
class GroupChatScreen extends StatefulWidget {
  final Group group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final chatService = context.read<ChatService>();
    chatService.connectToGroup(widget.group.groupId);
  }

  void _disconnectWebSocket() {
    final chatService = context.read<ChatService>();
    chatService.disconnectFromGroup();
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.loadMessages(widget.group.groupId);
    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  // WebSocket接続
  Future<void> _connectWebSocket() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.connectToGroup(widget.group.groupId);
  }

  // WebSocket切断
  Future<void> _disconnectWebSocket() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.disconnectFromGroup();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);

    if (auth.currentUser == null) return;

    await chatService.sendMessage(
      groupId: widget.group.groupId,
      userId: auth.currentUser!.userId,
      nickname: auth.currentUser!.nickname ?? 'ゲスト',
      content: content,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendCheer(String targetUserId, String targetNickname) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);

    if (auth.currentUser == null) return;

    await chatService.sendCheerMessage(
      widget.group.groupId,
      auth.currentUser!.userId,
      auth.currentUser!.nickname ?? 'ゲスト',
      targetNickname,
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name),
            Text(
              '${widget.group.memberIds.length}人',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // グループ情報画面へ遷移（後で実装）
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: Consumer<ChatService>(
                      builder: (context, chatService, _) {
                        final messages = chatService.getMessages(
                          widget.group.groupId,
                        );

                        if (messages.isEmpty) {
                          return const Center(
                            child: Text('まだメッセージがありません\n最初のメッセージを送信しましょう！'),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isCurrentUser =
                                Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                ).currentUser?.userId ==
                                message.userId;

                            return _MessageBubble(
                              message: message,
                              isCurrentUser: isCurrentUser,
                              onCheer:
                                  () => _sendCheer(
                                    message.userId,
                                    message.nickname ?? 'ユーザー',
                                  ),
                              onReaction: (emoji) async {
                                final auth = Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                );
                                final chatService = Provider.of<ChatService>(
                                  context,
                                  listen: false,
                                );

                                if (auth.currentUser != null) {
                                  await chatService.addReaction(
                                    widget.group.groupId,
                                    message.messageId,
                                    auth.currentUser!.userId,
                                    emoji,
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildInputArea(),
                ],
              ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'メッセージを入力...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// メッセージバブル
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final VoidCallback onCheer;
  final Function(String emoji) onReaction;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.onCheer,
    required this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    // システムメッセージの場合
    if (message.type == ChatMessageType.system) {
      return _buildSystemMessage(context);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              child: Text(
                (message.nickname ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser && message.nickname != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 8),
                    child: Text(
                      message.nickname!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                InkWell(
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _getMessageColor(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.type != ChatMessageType.text)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _getMessageTypeIcon(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.sentAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (message.metadata?['reactions'] != null) ...[
                      const SizedBox(width: 8),
                      _buildReactions(context),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    final reactions = message.metadata!['reactions'] as List;
    final reactionCounts = <String, int>{};

    for (final reaction in reactions) {
      final emoji = reaction['emoji'] as String;
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    }

    return Wrap(
      spacing: 4,
      children:
          reactionCounts.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${entry.key} ${entry.value}',
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
    );
  }

  Color _getMessageColor(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.wakeUp:
        return Colors.orange[100]!;
      case ChatMessageType.achievement:
        return Colors.amber[100]!;
      case ChatMessageType.cheer:
        return Colors.pink[100]!;
      default:
        return isCurrentUser
            ? Theme.of(context).primaryColor
            : Colors.grey[300]!;
    }
  }

  String _getMessageTypeIcon() {
    switch (message.type) {
      case ChatMessageType.wakeUp:
        return '🌅';
      case ChatMessageType.achievement:
        return '🏆';
      case ChatMessageType.cheer:
        return '💪';
      default:
        return '';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('応援する'),
                onTap: () {
                  Navigator.pop(context);
                  onCheer();
                },
              ),
              ListTile(
                leading: const Text('👍', style: TextStyle(fontSize: 24)),
                title: const Text('いいね'),
                onTap: () {
                  Navigator.pop(context);
                  onReaction('👍');
                },
              ),
              ListTile(
                leading: const Text('❤️', style: TextStyle(fontSize: 24)),
                title: const Text('ハート'),
                onTap: () {
                  Navigator.pop(context);
                  onReaction('❤️');
                },
              ),
              ListTile(
                leading: const Text('😊', style: TextStyle(fontSize: 24)),
                title: const Text('笑顔'),
                onTap: () {
                  Navigator.pop(context);
                  onReaction('😊');
                },
              ),
              ListTile(
                leading: const Text('🔥', style: TextStyle(fontSize: 24)),
                title: const Text('熱い'),
                onTap: () {
                  Navigator.pop(context);
                  onReaction('🔥');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
