/**
 * BLE モーションイベントの型定義
 */

export type MotionEventType = 
  | 'OPEN'              // 扉・引き出しを開けた
  | 'LIFT'              // 持ち上げた
  | 'SHAKE'             // 軽く振った
  | 'CLOSE'             // 閉じた
  | 'OPEN_LIFT_CLOSE'   // 一連の動作完了
  | 'FALSE';            // やったフリ検出

export interface BLEMotionEvent {
  tag_id: string;          // デバイス識別子 (例: "device_01")
  event: MotionEventType;  // イベントタイプ
  confidence: number;      // 0.0-1.0 の信頼度
  ts: number;              // Unix timestamp (秒)
  duration_ms?: number;    // シーケンス全体の所要時間（ミリ秒）
}

/**
 * BLE タグの登録情報
 */
export interface BLETag {
  tag_id: string;           // BLE デバイスの識別子
  name: string;             // ユーザーが付けた名前（例: "玄関の鍵"）
  mission_step_id: string;  // 紐づけるミッションステップ ID
  device_id?: string;       // BLE Device ID (Web Bluetooth API)
  last_seen?: number;       // 最後に検出した時刻 (Unix timestamp)
  battery_level?: number;   // バッテリー残量 (0-100)
}

/**
 * BLE 接続状態
 */
export interface BLEConnection {
  device: BluetoothDevice;
  server: BluetoothRemoteGATTServer;
  characteristic: BluetoothRemoteGATTCharacteristic;
  tag: BLETag;
}

/**
 * BLE GATT Service UUID
 */
export const BLE_SERVICE_UUID = '0000180f-0000-1000-8000-00805f9b34fb';

/**
 * BLE GATT Characteristic UUID (Motion Event)
 */
export const BLE_CHARACTERISTIC_UUID = '00002a19-0000-1000-8000-00805f9b34fb';
