# Google Playストアリリースガイド

## 事前準備

### 1. Google Play Console アカウント作成
- [Google Play Console](https://play.google.com/console) にアクセス
- デベロッパーアカウントを作成（$25の登録料が必要）

### 2. アプリの署名キー生成
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` ファイル作成：
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-keystore>/upload-keystore.jks
```

### 3. Railway APIデプロイ
1. Rails APIをRailwayにデプロイ
2. デプロイ完了後のURLを取得
3. `lib/services/api_service.dart` のbaseUrlを更新：
```dart
static const String baseUrl = 'https://your-app.railway.app/api/v1';
```
4. `lib/services/websocket_service.dart` のwsUrlを更新：
```dart
static const String wsUrl = 'wss://your-app.railway.app/cable';
```

### 4. アプリアイコン作成
- 512x512pxのアプリアイコンを作成
- [App Icon Generator](https://appicon.co/) 等で各サイズ生成
- `android/app/src/main/res/` 配下に配置

### 5. スクリーンショット準備
- 最低2枚、推奨8枚のスクリーンショット
- 縦向き: 1080x1920px または 1440x2560px
- 主要機能を表示：
  - ホーム画面（統計・ランキング）
  - グループ作成/参加
  - チャット画面
  - 設定画面

## ビルド手順

### 1. プロダクションビルド
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

生成されたAABファイル：
`build/app/outputs/bundle/release/app-release.aab`

### 2. APKビルド（テスト用）
```bash
flutter build apk --release
```

## Google Play Console設定

### 1. アプリ作成
- 「アプリを作成」をクリック
- アプリ名: 「めざましリレー」
- デフォルトの言語: 日本語
- アプリまたはゲーム: アプリ
- 無料または有料: 無料

### 2. ストア掲載情報
- **アプリ名**: めざましリレー
- **簡単な説明** (80文字):
  ```
  朝起きられない人のためのグループ目覚ましアプリ。友達と一緒に早起き習慣を身につけよう！
  ```
- **詳細な説明** (4000文字):
  ```
  めざましリレーは、朝起きるのが苦手な人のための革新的なグループ目覚ましアプリです。

  【主な機能】
  ✓ グループで目覚まし - 友達と一緒に起きるから続けられる
  ✓ リアルタイムチャット - 朝のモチベーションを共有
  ✓ 起床統計 - 自分の習慣を可視化
  ✓ ランキング - 仲間と競い合って早起き習慣を
  ✓ 匿名参加 - GRAVITYアカウントで簡単開始
  
  【こんな人におすすめ】
  • 朝起きるのが苦手
  • 一人だと続かない
  • 友達と早起き習慣をつけたい
  • 健康的な生活習慣を目指している
  
  【特徴】
  • 簡単なグループ作成・参加
  • 招待コードで友達を招待
  • 起床記録の自動保存
  • データは安全に暗号化
  
  仲間と一緒に、楽しく早起き習慣を身につけましょう！
  ```

### 3. グラフィック素材
- **アプリアイコン**: 512x512px PNG
- **フィーチャーグラフィック**: 1024x500px PNG
- **スクリーンショット**: 最低2枚（縦向き）

### 4. 分類
- **アプリのカテゴリ**: 健康&フィットネス または ライフスタイル
- **コンテンツのレーティング**: 全年齢対象

### 5. プライバシーポリシー
- URL: GitHub Pagesや自社サイトにホスト
- 内容: 収集するデータ、使用目的、セキュリティ対策

### 6. リリース作成
1. 「本番環境」→「リリースを作成」
2. AABファイルをアップロード
3. リリースノートを記入：
   ```
   初回リリース
   - グループ目覚まし機能
   - リアルタイムチャット
   - 起床統計・ランキング
   - GRAVITY式アカウント連携
   ```

### 7. 審査提出
- すべての必須項目を完了
- 「審査に送信」をクリック
- 通常1-3日で審査結果が通知されます

## リリース後

### バージョン更新時
1. `pubspec.yaml` のversionを更新
   ```yaml
   version: 1.0.1+2  # 1.0.1がバージョン名、2がビルド番号
   ```
2. 変更内容を実装
3. ビルド & アップロード
4. リリースノートに変更点を記載

### モニタリング
- クラッシュレポート確認
- ユーザーレビュー対応
- 統計データ分析

## トラブルシューティング

### ビルドエラー
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### 署名エラー
- `key.properties` のパスを確認
- キーストアファイルの存在を確認

### 審査却下
- ポリシー違反の内容を確認
- 修正してから再提出

## 参考リンク
- [Flutter - Android リリース](https://docs.flutter.dev/deployment/android)
- [Google Play Console ヘルプ](https://support.google.com/googleplay/android-developer)
