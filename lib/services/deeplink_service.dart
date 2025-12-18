import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'storage_service.dart';
import 'auth_service.dart';

/// ディープリンク処理サービス（グループ招待URL対応）
///
/// URLスキーマ: mezamashirelay://invite/{inviteCode}
/// 例: mezamashirelay://invite/ABC123
class DeeplinkService {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  BuildContext? _context;
  bool _initialized = false;

  /// サービス初期化
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // アプリ起動時の初期リンクを処理
    _handleInitialLink();

    // アプリ実行中のリンクを監視
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeeplink(uri);
      },
      onError: (err) {
        debugPrint('Deeplink error: $err');
      },
    );
  }

  /// BuildContextを設定（Navigatorアクセス用）
  void setContext(BuildContext context) {
    _context = context;
  }

  /// 初期リンク処理（コールドスタート時）
  Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeeplink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }
  }

  /// ディープリンク処理
  void _handleDeeplink(Uri uri) {
    if (_context == null) {
      debugPrint('Context not set, cannot handle deeplink: $uri');
      return;
    }

    // mezamashirelay://invite/{inviteCode}
    if (uri.scheme == 'mezamashirelay' && uri.host == 'invite') {
      final inviteCode =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;

      if (inviteCode != null) {
        _handleGroupInvite(inviteCode);
      }
    }
  }

  /// グループ招待処理
  Future<void> _handleGroupInvite(String inviteCode) async {
    if (_context == null) return;

    final storage = Provider.of<StorageService>(_context!, listen: false);
    final auth = Provider.of<AuthService>(_context!, listen: false);

    final currentUser = auth.currentUser;
    if (currentUser == null) {
      _showError('ユーザー情報の取得に失敗しました');
      return;
    }

    // 招待コードでグループを検索
    final targetGroup = await storage.findGroupByInviteCode(inviteCode);

    if (targetGroup == null) {
      _showError('招待コード「$inviteCode」のグループが見つかりません');
      return;
    }

    // 既に参加済みかチェック
    if (targetGroup.memberIds.contains(currentUser.userId)) {
      _showSuccess('既にグループ「${targetGroup.name}」に参加しています');
      return;
    }

    // グループに参加
    await storage.joinGroupByInviteCode(
      targetGroup.inviteCode,
      currentUser.userId,
    );
    _showSuccess('グループ「${targetGroup.name}」に参加しました！');
  }

  /// 成功メッセージ表示
  void _showSuccess(String message) {
    if (_context == null) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// エラーメッセージ表示
  void _showError(String message) {
    if (_context == null) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// サービス破棄
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
    _initialized = false;
  }
}
