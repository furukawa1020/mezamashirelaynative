import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/group.dart';

// SNS共有サービス
class ShareService {
  // 汎用共有（OSのシェアシート）
  static Future<void> shareGroup(Group group) async {
    await Share.share(
      group.getShareText(),
      subject: '「${group.name}」に参加しよう！',
    );
  }

  // LINE共有
  static Future<void> shareToLine(Group group) async {
    final text = Uri.encodeComponent(group.getShareText());
    final url = 'https://line.me/R/msg/text/?$text';
    await _launchUrl(url);
  }

  // X (Twitter)共有
  static Future<void> shareToX(Group group) async {
    final text = Uri.encodeComponent(group.getShareText());
    final url = 'https://twitter.com/intent/tweet?text=$text';
    await _launchUrl(url);
  }

  // Facebook共有
  static Future<void> shareToFacebook(Group group) async {
    final url = Uri.encodeComponent(group.deepLink);
    final fbUrl = 'https://www.facebook.com/sharer/sharer.php?u=$url';
    await _launchUrl(fbUrl);
  }

  // Instagram（ストーリーズ共有は制限あり、代わりにクリップボード）
  static Future<void> shareToInstagram(Group group) async {
    // Instagramは直接共有APIがないため、テキストをクリップボードにコピー
    await Share.share(
      group.getShareText(),
      subject: 'Instagramに投稿してください',
    );
  }

  // Slack共有
  static Future<void> shareToSlack(Group group) async {
    final text = Uri.encodeComponent(group.getShareText());
    final url = 'https://slack.com/intl/ja-jp/share?url=${Uri.encodeComponent(group.deepLink)}&text=$text';
    await _launchUrl(url);
  }

  // Discord共有（Webhook経由は別途実装が必要、ここではテキスト共有）
  static Future<void> shareToDiscord(Group group) async {
    await Share.share(
      group.getShareText(),
      subject: 'Discordで共有してください',
    );
  }

  // URL起動ヘルパー
  static Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  // QRコード表示用のデータ取得
  static String getQrData(Group group) {
    return group.deepLink;
  }
}
