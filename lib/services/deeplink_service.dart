import 'dart:async';
import 'package:uni_links/uni_links.dart';
import '../services/storage_service.dart';

// ディープリンク処理サービス
class DeeplinkService {
  StreamSubscription? _linkSubscription;
  final StorageService _storageService = StorageService();
<<<<<<< HEAD

=======
  
>>>>>>> 1e46074db814be4439fd1dd749b81dbe9b3dd55b
  // ディープリンクハンドラ（UI側で設定）
  Function(String inviteCode)? onInviteCodeReceived;

  // 初期化
  void initialize() {
    _handleInitialLink();
    _handleIncomingLinks();
  }

  // 初回起動時のリンク処理
  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _processLink(initialLink);
      }
    } catch (e) {
      print('Initial link error: $e');
    }
  }

  // アプリ実行中のリンク処理
  void _handleIncomingLinks() {
<<<<<<< HEAD
    _linkSubscription = linkStream.listen(
      (String? link) {
        if (link != null) {
          _processLink(link);
        }
      },
      onError: (err) {
        print('Link stream error: $err');
      },
    );
=======
    _linkSubscription = linkStream.listen((String? link) {
      if (link != null) {
        _processLink(link);
      }
    }, onError: (err) {
      print('Link stream error: $err');
    });
>>>>>>> 1e46074db814be4439fd1dd749b81dbe9b3dd55b
  }

  // リンク解析と処理
  void _processLink(String link) {
    final uri = Uri.parse(link);
<<<<<<< HEAD

    // mezamashi://join/{inviteCode}
    if (uri.scheme == 'mezamashi' && uri.host == 'join') {
      final inviteCode =
          uri.pathSegments.isNotEmpty
              ? uri.pathSegments[0]
              : uri.queryParameters['code'];

=======
    
    // mezamashi://join/{inviteCode}
    if (uri.scheme == 'mezamashi' && uri.host == 'join') {
      final inviteCode = uri.pathSegments.isNotEmpty 
          ? uri.pathSegments[0] 
          : uri.queryParameters['code'];
      
>>>>>>> 1e46074db814be4439fd1dd749b81dbe9b3dd55b
      if (inviteCode != null && inviteCode.isNotEmpty) {
        onInviteCodeReceived?.call(inviteCode);
      }
    }
  }

  // クリーンアップ
  void dispose() {
    _linkSubscription?.cancel();
  }
}
