import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

// WebSocketサービス - Action Cable接続
class WebSocketService {
  // 開発環境: localhost、本番環境: Railway URL
  static const String wsUrl = 'ws://localhost:3000/cable';

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _currentGroupId;

  // メッセージ受信コールバック
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;

  // グループチャンネルに接続
  Future<void> connect(String groupId) async {
    try {
      if (_isConnected && _currentGroupId == groupId) {
        return; // 既に接続済み
      }

      // 既存接続をクローズ
      await disconnect();

      _currentGroupId = groupId;
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 接続確認
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          onDisconnected?.call();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _isConnected = false;
          onDisconnected?.call();
        },
      );

      // Action Cable購読メッセージ送信
      _subscribe(groupId);
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _isConnected = false;
    }
  }

  // チャンネル購読
  void _subscribe(String groupId) {
    if (_channel == null) return;

    final subscribeMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ChatChannel', 'group_id': groupId}),
    });

    _channel!.sink.add(subscribeMessage);
    _isConnected = true;
    onConnected?.call();
  }

  // メッセージ処理
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      // Action Cableのメッセージタイプを判定
      if (data['type'] == 'welcome') {
        debugPrint('WebSocket: Connected');
      } else if (data['type'] == 'ping') {
        // pingメッセージは無視
      } else if (data['type'] == 'confirm_subscription') {
        debugPrint('WebSocket: Subscribed to ChatChannel');
      } else if (data['message'] != null) {
        // チャットメッセージ受信
        final messageData = data['message'];
        onMessageReceived?.call(messageData);
      }
    } catch (e) {
      debugPrint('Failed to parse WebSocket message: $e');
    }
  }

  // メッセージ送信（Action Cable経由）
  void sendMessage({
    required String groupId,
    required String content,
    required String senderUserId,
    String messageType = 'text',
  }) {
    if (_channel == null || !_isConnected) {
      debugPrint('WebSocket not connected');
      return;
    }

    final message = jsonEncode({
      'command': 'message',
      'identifier': jsonEncode({'channel': 'ChatChannel', 'group_id': groupId}),
      'data': jsonEncode({
        'action': 'send_message',
        'group_id': groupId,
        'content': content,
        'sender_user_id': senderUserId,
        'message_type': messageType,
      }),
    });

    _channel!.sink.add(message);
  }

  // 接続解除
  Future<void> disconnect() async {
    if (_channel != null) {
      // 購読解除メッセージ送信
      if (_isConnected && _currentGroupId != null) {
        final unsubscribeMessage = jsonEncode({
          'command': 'unsubscribe',
          'identifier': jsonEncode({
            'channel': 'ChatChannel',
            'group_id': _currentGroupId,
          }),
        });
        _channel!.sink.add(unsubscribeMessage);
      }

      await _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      _currentGroupId = null;
    }
  }

  // 再接続
  Future<void> reconnect() async {
    if (_currentGroupId != null) {
      await connect(_currentGroupId!);
    }
  }
}
