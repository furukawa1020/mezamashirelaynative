# めざましリレー - Flutter Native App

匿名ベースの起床リレーアプリ（Android/iOS対応）

## Features

-  **匿名アカウント**: メールアドレス不要、UUID自動生成
-  **ローカルファースト**: SharedPreferencesで全データ保存
-  **招待コード**: 6桁コードでグループ参加
-  **ディープリンク**: `mezamashi://join/{code}`
-  **SNS共有**: LINE/X/Facebook/Instagram対応
-  **BLE連携**: XIAO ESP32C3 + MPU6050センサー対応
-  **グループモード**: RACE（競争）/ALL（全員クリア）

## Setup

```bash
flutter pub get
flutter run
```

## Architecture

- **Anonymous Auth**: UUID-based user system (no Firebase)
- **Local Storage**: SharedPreferences for all data
- **Deep Linking**: uni_links for group invitations
- **BLE**: flutter_blue_plus for sensor communication

## License

MIT
