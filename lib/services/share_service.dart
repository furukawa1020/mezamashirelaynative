import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/group.dart';

// SNS蜈ｱ譛峨し繝ｼ繝薙せ
class ShareService {
  // 豎守畑蜈ｱ譛会ｼ・S縺ｮ繧ｷ繧ｧ繧｢繧ｷ繝ｼ繝茨ｼ・
  static Future<void> shareGroup(Group group) async {
    await Share.share(group.getShareText(), subject: '縲・{group.name}縲阪↓蜿ょ刈縺励ｈ縺・ｼ・);
  }

  // LINE蜈ｱ譛・
  static Future<void> shareToLine(Group group) async {
    final text = Uri.encodeComponent(group.getShareText());
    final url = 'https://line.me/R/msg/text/?$text';
    await _launchUrl(url);
  }

  // X (Twitter)蜈ｱ譛・
  static Future<void> shareToX(Group group) async {
    final text = Uri.encodeComponent(group.getShareText());
    final url = 'https://twitter.com/intent/tweet?text=$text';
    await _launchUrl(url);
  }

  // Facebook蜈ｱ譛・
  static Future<void> shareToFacebook(Group group) async {
    final url = Uri.encodeComponent(group.deepLink);
    final fbUrl = 'https://www.facebook.com/sharer/sharer.php?u=$url';
    await _launchUrl(fbUrl);
  }

  // Instagram・医せ繝医・繝ｪ繝ｼ繧ｺ蜈ｱ譛峨・蛻ｶ髯舌≠繧翫∽ｻ｣繧上ｊ縺ｫ繧ｯ繝ｪ繝・・繝懊・繝会ｼ・
  static Future<void> shareToInstagram(Group group) async {
    // Instagram縺ｯ逶ｴ謗･蜈ｱ譛陰PI縺後↑縺・◆繧√√ユ繧ｭ繧ｹ繝医ｒ繧ｯ繝ｪ繝・・繝懊・繝峨↓繧ｳ繝斐・
    await Share.share(group.getShareText(), subject: 'Instagram縺ｫ謚慕ｨｿ縺励※縺上□縺輔＞');
  }

  // Slack蜈ｱ譛・
  static Future<void> shareToSlack(Group group) async {
    final text = Uri.encodeComponent(group.getShareText());
    final url =
        'https://slack.com/intl/ja-jp/share?url=${Uri.encodeComponent(group.deepLink)}&text=$text';
    await _launchUrl(url);
  }

  // Discord蜈ｱ譛会ｼ・ebhook邨檎罰縺ｯ蛻･騾泌ｮ溯｣・′蠢・ｦ√√％縺薙〒縺ｯ繝・く繧ｹ繝亥・譛会ｼ・
  static Future<void> shareToDiscord(Group group) async {
    await Share.share(group.getShareText(), subject: 'Discord縺ｧ蜈ｱ譛峨＠縺ｦ縺上□縺輔＞');
  }

  // URL襍ｷ蜍輔・繝ｫ繝代・
  static Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  // QR繧ｳ繝ｼ繝芽｡ｨ遉ｺ逕ｨ縺ｮ繝・・繧ｿ蜿門ｾ・
  static String getQrData(Group group) {
    return group.deepLink;
  }
}
