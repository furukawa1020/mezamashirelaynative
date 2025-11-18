# めざましリレー (Mezamashi Relay) — IoT × PWA 起床リレーアプリ

このリポジトリは、**XIAO ESP32C3 + MPU6050** を使った BLE センサと PWA を統合した起床リレーアプリです。

## 主な特徴

### PWA（Progressive Web App）
- **Vite + React (TypeScript)** のモダンなフロントエンド
- **Local-first** 設計：Firebase なしでも localStorage で完全動作
- **Web Bluetooth API** による BLE センサ連携
- **アラーム音**：天国と地獄の音楽がループ再生（全ステップ完了まで）
- **オフライン対応**：Service Worker + Install Prompt

### BLE IoT センサ（XIAO ESP32C3 + MPU6050）
- **モーションパターン検出**：OPEN / LIFT / SHAKE / CLOSE / FALSE（やったフリ）
- **シーケンス認識**：OPEN → LIFT → CLOSE の一連動作を1ステップとして扱う
- **BLE GATT Notify**：JSON ペイロードでイベント送信
- **100Hz サンプリング**：高精度な動作検出

### その他
- **グループモード**：RACE（競争）/ ALL（全員クリア）
- **データエクスポート/インポート**：QR コード共有、自動バックアップ
- **マルチタグ対応**：最大3台の BLE タグを登録可能

## クイックスタート

### PWA 側のセットアップ

1. **Node.js (推奨 18+)** をインストール
2. 依存関係をインストール:
   ```powershell
   npm install
   ```

3. 開発サーバ起動:
   ```powershell
   npm run dev
   ```

4. （オプション）Firebase を使う場合:
   - `.env.example` を `.env` にコピー
   - Firebase プロジェクトを作成し、設定値を `.env` に記入
   - `VITE_USE_FIREBASE=1` を設定

### BLE センサ側のセットアップ

1. **XIAO ESP32C3 + MPU6050** を配線:
   ```
   MPU6050 VCC → XIAO 3.3V
   MPU6050 GND → XIAO GND
   MPU6050 SDA → XIAO D4 (GPIO6)
   MPU6050 SCL → XIAO D5 (GPIO7)
   ```

2. **PlatformIO** でファームウェアをアップロード:
   ```bash
   cd arduino/mezamashinochild
   pio run --target upload
   pio device monitor
   ```

3. シリアルモニタで "BLE: Advertising started" を確認

詳細は [docs/BLE_TESTING_DEBUG.md](docs/BLE_TESTING_DEBUG.md) を参照してください。

デプロイ
- Vercel や Netlify にデプロイできます。ビルドコマンドは `npm run build`、公開ディレクトリは `dist` です。
- Vercel や Netlify にデプロイできます。ビルドコマンドは `npm run build`、公開ディレクトリは `dist` です。

デプロイ手順（Netlify）

1. GitHub にリポジトリを push
2. Netlify にログイン → New site from Git → GitHub を選択
3. Build command: `npm run build`、Publish directory: `dist`
4. (重要) Netlify の Site settings → Build & deploy → Environment に Firebase の設定値を追加してください（例: FIREBASE_API_KEY, FIREBASE_AUTH_DOMAIN, FIREBASE_PROJECT_ID）。

デプロイ手順（Firebase Hosting）

1. Firebase CLI をインストール:

```powershell
npm install -g firebase-tools
```

2. Firebase にログイン:

```powershell
firebase login
```

3. プロジェクトを初期化（既に Firebase プロジェクトを作成済み）:

```powershell
firebase use --add
firebase init hosting
```

4. ビルドしてデプロイ:

```powershell
npm run build
firebase deploy --only hosting
```

注意: `src/services/auth.tsx` と `src/services/firestore.ts` の `firebaseConfig` に Firebase の Web 設定を貼り付けてください。Netlify や Firebase の環境変数を使う場合は、`src/services` 側で process.env の利用に切り替えてください（現状はファイル内定義の簡易版です）。

BLE タグ (ESP32C3 + MPU6050)
- `arduino/mezamashi_tag/mezamashi_tag.ino` を参照してください（サンプルコードを含む）。

次のステップ
- ミッション CRUD、セッション開始・完了ロジックを実装
- グループ機能（招待リンク／コード）を実装
- Web Bluetooth / Web NFC のフックを実装

ローカルファースト (local-first) モード (デフォルト)
-----------------------------------


このプロジェクトはローカルファースト（local-first）をデフォルトの動作にしています — つまり Firebase を使わず端末の `localStorage` のみで動きます。公開配布や簡易デモでの利用を想定しています。

特徴とトレードオフ
- 初期参加の摩擦がゼロ（メール不要、すぐ開始できる）
- 全データは端末ローカルに保存されるため、他端末との同期や復元はできません
- 公開運用や不正対策が必要な場合はサーバー側の導入を推奨します

使い方（ビルド／デプロイ時）

デフォルト（local-first）で動きます。Firebase を使いたい場合は明示的に環境変数 `VITE_USE_FIREBASE=1` を設定してください。

- 開発で Firebase を使う（PowerShell）:

```powershell
$env:VITE_USE_FIREBASE = '1'; npm run dev
```

- 本番ビルドで Firebase を使う（PowerShell）:

```powershell
$env:VITE_USE_FIREBASE = '1'; npm run build
```

ローカルモードでは表示名の編集やサインアウトが可能です（表示名は `localStorage` の `mz_local_user` キーに保存されます）。

必要に応じて、Netlify 等のホスティングで環境変数を設定することで、デプロイ先ごとに backend / local の切り替えができます。

データのエクスポート / インポート
--------------------------------

ローカルモードで生成されたデータは `localStorage` に保存されます。アプリにはエクスポート／インポート機能があり、JSON ファイルでバックアップや端末間の移行が可能です。

- ダッシュボードの「データ管理」からエクスポート/インポート/サンプルデータ投入ができます。
- JSON をインポートするとローカルデータが上書きされるので、インポート前にエクスポートしておくことを推奨します。

注意: インポートは本当にローカルのデータを上書きします。公開運用の際はサーバ同期を使ってください。

