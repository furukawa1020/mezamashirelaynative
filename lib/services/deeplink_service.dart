import 'dart:async';
import 'package:uni_links/uni_links.dart';
import '../services/storage_service.dart';

// 繝・ぅ繝ｼ繝励Μ繝ｳ繧ｯ蜃ｦ逅・し繝ｼ繝薙せ
class DeeplinkService {
  StreamSubscription? _linkSubscription;
  final StorageService _storageService = StorageService();

  
  // 繝・ぅ繝ｼ繝励Μ繝ｳ繧ｯ繝上Φ繝峨Λ・・I蛛ｴ縺ｧ險ｭ螳夲ｼ・
  Function(String inviteCode)? onInviteCodeReceived;

  // 蛻晄悄蛹・
  void initialize() {
    _handleInitialLink();
    _handleIncomingLinks();
  }

  // 蛻晏屓襍ｷ蜍墓凾縺ｮ繝ｪ繝ｳ繧ｯ蜃ｦ逅・
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

  // 繧｢繝励Μ螳溯｡御ｸｭ縺ｮ繝ｪ繝ｳ繧ｯ蜃ｦ逅・
  void _handleIncomingLinks() {
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
    _linkSubscription = linkStream.listen((String? link) {
      if (link != null) {
        _processLink(link);
      }
    }, onError: (err) {
      print('Link stream error: $err');
    });
  }

  // 繝ｪ繝ｳ繧ｯ隗｣譫舌→蜃ｦ逅・
  void _processLink(String link) {
    final uri = Uri.parse(link);

    // mezamashi://join/{inviteCode}
    if (uri.scheme == 'mezamashi' && uri.host == 'join') {
      final inviteCode =
          uri.pathSegments.isNotEmpty
              ? uri.pathSegments[0]
              : uri.queryParameters['code'];

    
    // mezamashi://join/{inviteCode}
    if (uri.scheme == 'mezamashi' && uri.host == 'join') {
      final inviteCode = uri.pathSegments.isNotEmpty 
          ? uri.pathSegments[0] 
          : uri.queryParameters['code'];
      
      if (inviteCode != null && inviteCode.isNotEmpty) {
        onInviteCodeReceived?.call(inviteCode);
      }
    }
  }

  // 繧ｯ繝ｪ繝ｼ繝ｳ繧｢繝・・
  void dispose() {
    _linkSubscription?.cancel();
  }
}
