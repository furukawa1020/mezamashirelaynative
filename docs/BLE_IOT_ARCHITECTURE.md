# BLE IoT アーキテクチャ — めざましリレー × XIAO ESP32C3 + MPU6050

## 概要

このドキュメントは、Seeed XIAO ESP32C3 と MPU6050 を用いた BLE 開けしめセンサを「めざましリレー」PWA に統合するための設計書です。

## システム構成図

```
┌────────────────────────────────────────────────────────────────┐
│                        PWA (Browser)                           │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  React Components                                         │ │
│  │  - BLETagManager (scan/pair/register)                    │ │
│  │  - StepItem (auto-complete on BLE event)                 │ │
│  └──────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Services                                                 │ │
│  │  - useBLE() hook (Web Bluetooth API)                     │ │
│  │  - localStore (session_steps recording)                  │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
                              ↕ BLE (GATT Notify)
┌────────────────────────────────────────────────────────────────┐
│          XIAO ESP32C3 + MPU6050 (BLE Peripheral)              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Motion Pattern Detector                                  │ │
│  │  - 100Hz IMU sampling                                     │ │
│  │  - Angle change / velocity peak / settle time analysis   │ │
│  │  - Pattern: OPEN / LIFT / SHAKE / CLOSE / FALSE          │ │
│  └──────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Sequence Detector                                        │ │
│  │  - State machine: IDLE → OPEN → LIFT → CLOSE → DONE     │ │
│  │  - Emit compound event after full sequence               │ │
│  └──────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  BLE GATT Service                                         │ │
│  │  - Service UUID: 0x180F (custom)                         │ │
│  │  - Characteristic UUID: 0x2A19 (notify)                  │ │
│  │  - Payload: JSON {"tag_id", "event", "confidence", "ts"} │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

## データフロー

1. **センサ読み取り（100Hz）**  
   MPU6050 から加速度 (ax, ay, az) とジャイロ (gx, gy, gz) を読み取り

2. **モーションパターン分類**  
   - 角度変化 > 30° → OPEN / LIFT  
   - 速度ピーク後すぐ静止 → FALSE（やったフリ）  
   - 軽い振動 → SHAKE  
   - 元の角度に戻る → CLOSE

3. **シーケンス検出**  
   状態遷移: IDLE → OPEN → LIFT → CLOSE → DONE  
   完了したらイベントを生成

4. **BLE Notify 送信**  
   JSON ペイロード例:
   ```json
   {
     "tag_id": "device_01",
     "event": "OPEN_LIFT_CLOSE",
     "confidence": 0.95,
     "ts": 1710000000,
     "duration_ms": 1500
   }
   ```

5. **PWA 受信と処理**  
   - Web Bluetooth API で Notify を購読  
   - `tag_id` から対応する `mission_step_id` を検索  
   - `completeSessionStep()` を呼び出し  
   - サウンド/コンフェティ/バイブレーション

## BLE GATT 仕様

### Service
- **UUID**: `0000180f-0000-1000-8000-00805f9b34fb`  
  (Battery Service UUID を流用、または独自 UUID に変更可能)

### Characteristic (Motion Event)
- **UUID**: `00002a19-0000-1000-8000-00805f9b34fb`  
- **Properties**: Notify, Read  
- **Format**: UTF-8 JSON string (max 512 bytes)

### ペイロード仕様

```typescript
interface BLEMotionEvent {
  tag_id: string;          // デバイス識別子 (例: "device_01")
  event: MotionEventType;  // "OPEN_LIFT_CLOSE" | "OPEN" | "LIFT" | "SHAKE" | "FALSE"
  confidence: number;      // 0.0-1.0 の信頼度
  ts: number;              // Unix timestamp (秒)
  duration_ms?: number;    // シーケンス全体の所要時間（ミリ秒）
}

type MotionEventType = 
  | "OPEN"              // 扉・引き出しを開けた
  | "LIFT"              // 持ち上げた
  | "SHAKE"             // 軽く振った
  | "CLOSE"             // 閉じた
  | "OPEN_LIFT_CLOSE"   // 一連の動作完了
  | "FALSE";            // やったフリ検出
```

## モーションパターン検出アルゴリズム

### 1. OPEN（扉・引き出しを開ける）
- **条件**:
  - Y軸またはZ軸の角度変化 > 30°
  - 加速度ピーク < 2.5g (急激すぎない)
  - 静止時間 > 500ms (開けたまま保持)

### 2. LIFT（持ち上げ）
- **条件**:
  - Z軸加速度が 1.2g 以上に増加
  - X/Y軸の角度変化 > 20°
  - 静止時間 > 300ms (持ち上げたまま保持)

### 3. SHAKE（軽く振る）
- **条件**:
  - 加速度の標準偏差 > 0.3g
  - 周期的な振動（0.5~2Hz）
  - 持続時間 > 500ms

### 4. CLOSE（閉じる）
- **条件**:
  - OPEN 状態から元の角度（±10°）に戻る
  - 加速度ピーク < 1.5g

### 5. FALSE（やったフリ）
- **条件**:
  - 角度変化 > 30° かつ速度ピーク > 3g
  - 100ms 以内に静止（即戻し）
  - または開けた後すぐ（< 200ms）に閉じる

## シーケンス検出の状態遷移

```
IDLE → [検出: OPEN] → OPEN_STATE
                          ↓ (1秒以内)
                      [検出: LIFT] → LIFT_STATE
                          ↓ (2秒以内)
                      [検出: CLOSE] → 完了
                          ↓
                      Notify("OPEN_LIFT_CLOSE")
                          ↓
                      IDLE に戻る
```

- タイムアウト: 各状態で次の動作が来なければ IDLE に戻る
- 順序違反: LIFT → OPEN の順序なら無視または警告

## PWA 側の実装要件

### 1. BLE タグ管理
- `localStorage` に登録されたタグ情報を保存:
  ```typescript
  interface BLETag {
    tag_id: string;
    name: string;          // ユーザーが付けた名前（例: "玄関の鍵"）
    mission_step_id: string; // 紐づけるステップ
    last_seen?: number;    // 最後に検出した時刻
  }
  ```

### 2. Web Bluetooth API フロー
```typescript
// スキャン
const device = await navigator.bluetooth.requestDevice({
  filters: [{ services: ['0000180f-0000-1000-8000-00805f9b34fb'] }]
});

// 接続
const server = await device.gatt.connect();
const service = await server.getPrimaryService('0000180f-0000-1000-8000-00805f9b34fb');
const characteristic = await service.getCharacteristic('00002a19-0000-1000-8000-00805f9b34fb');

// Notify 購読
await characteristic.startNotifications();
characteristic.addEventListener('characteristicvaluechanged', (event) => {
  const value = event.target.value;
  const text = new TextDecoder().decode(value);
  const payload = JSON.parse(text); // BLEMotionEvent
  handleBLEEvent(payload);
});
```

### 3. セッション記録の拡張
`localStore` の `session_steps` に追加フィールド:
```typescript
interface SessionStep {
  id: string;
  session_id: string;
  step_id: string;
  result: 'pending' | 'success' | 'fail';
  completed_at?: number;
  // BLE 関連の追加
  ble_tag_id?: string;      // どのタグで完了したか
  ble_event?: string;       // どのイベントで完了したか
  ble_confidence?: number;  // 信頼度
  duration_ms?: number;     // 動作にかかった時間
}
```

### 4. グレースフルデグレード
- BLE が使えない場合（iOS Safari、古いブラウザ）は手動ボタンで完了
- NFC にフォールバック（Web NFC API）
- エラーハンドリングとユーザーへの明示的なメッセージ

## セキュリティとプライバシー

- BLE はペアリング時にユーザーの明示的な許可が必要（Web Bluetooth API の仕様）
- `tag_id` は端末固有だがユーザーを特定する情報は含まない
- センサデータは端末内で処理し、生データを送信しない
- PWA 側は localStorage に保存（クラウド同期時は暗号化を推奨）

## テスト方法

### ファームウェア
1. シリアルモニタで IMU 値をログ出力
2. 手動でドアを開閉し、パターン検出をログ確認
3. BLE スキャンアプリ（nRF Connect など）で Notify を確認

### PWA
1. Chrome DevTools の Bluetooth 設定で実機を許可
2. `chrome://bluetooth-internals` でデバイス検出を確認
3. コンソールログで受信イベントを確認
4. localStore の `session_steps` に `ble_tag_id` が記録されているか確認

## 改善案

- **機械学習**: TensorFlow Lite Micro で動作分類の精度向上
- **バッテリー最適化**: Deep Sleep モードでイベント駆動型に
- **複数タグの協調**: 複数のタグが同時にイベントを送る場合の調停
- **クラウド分析**: Firestore に動作ログを蓄積して統計分析
- **NFC との連携**: BLE が切れたら NFC で補完

---

次のステップ: XIAO ESP32C3 のファームウェア実装
