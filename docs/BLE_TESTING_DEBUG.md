# BLE IoT センサ統合 — テスト・デバッグ・改善ガイド

## テスト方法

### 1. ファームウェアのテスト（XIAO ESP32C3）

#### 必要な機材
- Seeed XIAO ESP32C3
- MPU6050 (GY-521) モジュール
- ブレッドボード、ジャンパーワイヤー
- USB-C ケーブル
- Arduino IDE (ESP32 ボード追加済み)

#### セットアップ手順

1. **配線**:
   ```
   MPU6050 VCC → XIAO 3.3V
   MPU6050 GND → XIAO GND
   MPU6050 SDA → XIAO D4 (GPIO6)
   MPU6050 SCL → XIAO D5 (GPIO7)
   ```

2. **ファームウェア書き込み**:
   
   **方法A: PlatformIO（推奨）**:
   ```bash
   cd arduino/mezamashinochild
   pio run --target upload
   pio device monitor
   ```

   **方法B: Arduino IDE**:
   ```
   1. Arduino IDE で arduino/mezamashinochild/src/main.cpp を開く
   2. ボード: "XIAO_ESP32C3" を選択
   3. 必要なライブラリをインストール:
      - Adafruit MPU6050
      - Adafruit Unified Sensor
      - ArduinoJson
   4. シリアルポートを選択
   5. アップロード
   ```

4. **シリアルモニタで動作確認**:
   ```
   1. シリアルモニタを開く (115200 baud)
   2. 以下のようなログが表示されることを確認:
      - "MPU6050 initialized"
      - "BLE: Advertising started"
      - "angle=X.X accel=Y.YYg speed=Z.Zdeg/s"
   ```

5. **モーションパターンのテスト**:
   - **OPEN**: センサを取り付けた扉・引き出しを開ける → "Event: OPEN" がログに出る
   - **LIFT**: センサを持ち上げる → "Event: LIFT" がログに出る
   - **CLOSE**: 元の位置に戻す → "Event: CLOSE" がログに出る
   - **FALSE**: 高速で動かしてすぐ戻す → "Event: FALSE" がログに出る
   - **OPEN_LIFT_CLOSE**: 開けて→持ち上げて→閉じる を連続実行 → "Sequence: COMPLETE" がログに出る

6. **BLE 動作確認（スマホアプリ）**:
   - nRF Connect (Android/iOS) をインストール
   - "MezamashiTag_01" をスキャン
   - 接続して Service `0x180F` を開く
   - Characteristic `0x2A19` の Notify を有効化
   - センサを動かすと JSON ペイロードが届く:
     ```json
     {"tag_id":"device_01","event":"OPEN","confidence":0.8,"ts":1710000000}
     ```

---

### 2. PWA のテスト（Web Bluetooth）

#### 動作環境
- **推奨ブラウザ**: Chrome 89+ / Edge 89+ (Windows/macOS/Android)
- **非対応**: iOS Safari（Web Bluetooth API 非対応）

#### テスト手順

1. **ローカルで PWA を起動**:
   ```bash
   npm run dev
   ```

2. **BLE タグをスキャン**:
   - ダッシュボードの「BLE タグ管理」セクションへ移動
   - 「+ タグを追加」ボタンをクリック
   - ブラウザのデバイス選択ダイアログで "MezamashiTag_01" を選択
   - ペアリング完了後、タグが一覧に追加される

3. **ステップに紐づけ**:
   - 事前にミッションとステップを作成しておく（例: 「ベッドから出る」）
   - タグのドロップダウンからステップを選択

4. **セッションを開始**:
   - ダッシュボードで「今日のセッション開始」をクリック
   - ミッション ID を入力してセッション作成

5. **BLE イベントで自動完了をテスト**:
   - センサを動かす（OPEN → LIFT → CLOSE の順序）
   - PWA のコンソールに `[BLE Event]` ログが表示される
   - トースト通知「✅ (タグ名) で完了しました」が表示される
   - サウンド・バイブレーションが発動（ミュートでない場合）
   - セッションステップが「success」に更新される

6. **localStorage でデータ確認**:
   - Chrome DevTools → Application → Local Storage
   - `mz_store_session_steps` キーを開く
   - 完了したステップに以下のフィールドが追加されているか確認:
     ```json
     {
       "ble_tag_id": "device_01",
       "ble_event": "OPEN_LIFT_CLOSE",
       "ble_confidence": 0.95,
       "duration_ms": 1500
     }
     ```

---

## デバッグ方法

### ファームウェア側

#### 問題: MPU6050 が初期化できない
- **原因**: I2C 配線ミス、不良モジュール
- **対処**:
  1. 配線を再確認（特に SDA/SCL の入れ替え）
  2. I2C スキャンコードで 0x68 が検出されるか確認:
     ```cpp
     Wire.begin(SDA_PIN, SCL_PIN);
     Wire.beginTransmission(0x68);
     if (Wire.endTransmission() == 0) {
       Serial.println("MPU6050 found at 0x68");
     }
     ```

#### 問題: BLE アドバタイズが見えない
- **原因**: ESP32 の BLE スタックエラー、リセット不足
- **対処**:
  1. ボタンリセット（XIAO の RST ボタン）
  2. シリアルモニタで "BLE: Advertising started" を確認
  3. nRF Connect で周辺をスキャン

#### 問題: モーションパターンが誤検出される
- **原因**: しきい値が環境に合っていない
- **対処**:
  1. シリアルモニタで `angle=`, `accel=`, `speed=` の値を観察
  2. `ANGLE_THRESHOLD`, `ACCEL_PEAK_THRESHOLD` を調整
  3. 誤検出が多い場合は静止判定時間（`SETTLE_TIME_MS`）を延ばす

#### 問題: やったフリ（FALSE）が検出されない
- **原因**: 速度しきい値が低すぎる
- **対処**:
  1. `FALSE_SPEED_THRESHOLD` を下げる（例: 3.0 → 2.5）
  2. 高速動作後の静止判定時間（100ms）を調整

---

### PWA 側

#### 問題: Web Bluetooth API が使えない
- **原因**: ブラウザ非対応、HTTPS でない
- **対処**:
  1. Chrome/Edge を使用
  2. localhost 以外は HTTPS 必須（Netlify は自動 HTTPS）
  3. iOS は非対応 → 代替手段（NFC/手動）へ誘導

#### 問題: BLE スキャンでデバイスが見つからない
- **原因**: BLE がオフ、距離が遠い、ファームウェアのアドバタイズ失敗
- **対処**:
  1. PC/スマホの Bluetooth をオンにする
  2. センサを PC/スマホに近づける（1m 以内推奨）
  3. ファームウェアのシリアルログで "Advertising started" を確認

#### 問題: Notify が受信できない
- **原因**: 特性の UUID ミスマッチ、startNotifications 失敗
- **対処**:
  1. Chrome DevTools の Console でエラーを確認
  2. `chrome://bluetooth-internals` で Service/Characteristic を確認
  3. ファームウェアと PWA の UUID が一致しているか確認

#### 問題: イベントを受信してもステップが完了しない
- **原因**: タグとステップの紐づけが未設定、セッション未開始
- **対処**:
  1. BLETagManager でタグにステップを紐づける
  2. セッションを開始して session_steps を作成する
  3. Console で `[BLE Event]` と `[BLE] Completed session_step` のログを確認

#### 問題: 複数タグが同時にイベントを送るとエラー
- **現状**: 未対応（競合回避ロジックなし）
- **対処**:
  1. 短期: タグごとに異なるステップに紐づけて競合を避ける
  2. 長期: イベントキューと調停ロジックを実装（後述の改善案）

---

## 改善案

### 1. 機械学習によるパターン認識
- **目的**: 誤検出を減らし、より複雑な動作パターンを認識
- **手法**:
  - TensorFlow Lite Micro を ESP32 に組み込む
  - 加速度・ジャイロの時系列データを学習（ラベル: OPEN/LIFT/SHAKE/CLOSE/FALSE）
  - 簡易モデル: 1D CNN（入力: 100サンプル × 6軸、出力: 5クラス）
- **参考**: [TensorFlow Lite for Microcontrollers](https://www.tensorflow.org/lite/microcontrollers)

### 2. バッテリー最適化
- **現状**: 常時 100Hz サンプリングでバッテリー消費が大きい
- **改善**:
  - Deep Sleep モード: 静止時は割り込み駆動（MPU6050 の Motion Detect 機能）
  - サンプリング周波数を動的に変更（静止時 10Hz、動作時 100Hz）
  - BLE の Connection Interval を延ばす（例: 100ms → 500ms）
- **効果**: バッテリー寿命が数倍に延びる

### 3. 複数タグの協調
- **問題**: 複数のタグが同時にイベントを送ると競合する
- **解決策**:
  - PWA 側でイベントキューを実装し、confidence 順に処理
  - タイムスタンプ（`ts`）で先着順を判定
  - 同一ステップに複数タグが紐づく場合は「いずれか1つ完了」でOK

### 4. NFC との連携
- **目的**: BLE が使えない環境（iOS）での補完
- **実装**:
  - XIAO ESP32C3 に PN532 NFC モジュールを追加
  - Web NFC API（Android Chrome のみ対応）で読み取り
  - BLE と同じ JSON ペイロードを NFC タグに書き込む

### 5. クラウド分析
- **目的**: ユーザーの動作ログを蓄積して統計分析
- **実装**:
  - BLE イベントを Firestore に記録（`ble_events` コレクション）
  - Cloud Functions でダッシュボード生成（完了率、誤検出率など）
  - BigQuery でデータ分析（動作パターンの傾向、時間帯別の成功率など）

### 6. リアルタイムフィードバック
- **目的**: ユーザーに動作状態をリアルタイム表示
- **実装**:
  - BLE イベントを受信したら PWA の画面上にリアルタイム表示
  - 例: 「OPEN 検出中...」→「LIFT 待機中...」→「完了！」
  - プログレスバーやアニメーションで視覚化

### 7. セキュリティ強化
- **現状**: BLE は暗号化されているが、JSON ペイロードは平文
- **改善**:
  - タグごとに秘密鍵を設定し、ペイロードに HMAC 署名を付ける
  - PWA 側で署名を検証して偽装イベントを防ぐ

---

## よくある質問（FAQ）

**Q1: iOS で使えますか？**  
A: iOS Safari は Web Bluetooth API に対応していません。NFC（Web NFC API も iOS 非対応）または手動ボタンで代替してください。

**Q2: センサを何個まで登録できますか？**  
A: 現在の実装では制限なしですが、BLE の同時接続数は通常 3～7 個程度が上限です（ブラウザ・OS による）。

**Q3: バッテリーはどのくらい持ちますか？**  
A: 常時 100Hz サンプリング + BLE Notify の場合、500mAh バッテリーで約 6～12 時間です。Deep Sleep を実装すれば数日～1週間に延びます。

**Q4: ファームウェアのアップデート方法は？**  
A: USB-C ケーブルで PC に接続し、Arduino IDE で再度アップロードしてください。OTA（Over-The-Air）更新は未実装です。

**Q5: BLE が切断されたらどうなりますか？**  
A: PWA 側の `reconnectAll()` で自動再接続を試みます。手動で「🔄 再接続」ボタンを押すこともできます。

---

## 次のステップ

1. **本番環境へのデプロイ**:
   - Netlify に PWA をデプロイ（HTTPS 必須）
   - センサを実際の使用場所に設置（玄関のドア、引き出しなど）

2. **ユーザーテスト**:
   - 複数ユーザーで実際に使ってフィードバックを収集
   - 誤検出率・完了成功率を記録

3. **機能拡張**:
   - 上記の改善案を順次実装
   - Firestore への移行とクラウド分析

4. **ドキュメント更新**:
   - ユーザーマニュアルの作成（センサの取り付け方、トラブルシュート）
   - API ドキュメント（BLE ペイロード仕様）

---

Generated: 2025-11-18
