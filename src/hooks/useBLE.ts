/**
 * useBLE - Web Bluetooth API を使った BLE タグ管理フック
 * 
 * 機能:
 * - BLE デバイスのスキャン・ペアリング
 * - BLE Notify の購読とイベント受信
 * - タグの登録・削除・ステップ紐づけ
 * - localStorage への永続化
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import {
  BLETag,
  BLEMotionEvent,
  BLEConnection,
  BLE_SERVICE_UUID,
  BLE_CHARACTERISTIC_UUID,
} from '../types/ble';

const STORAGE_KEY = 'mz_ble_tags';

export function useBLE() {
  const [tags, setTags] = useState<BLETag[]>([]);
  const [connections, setConnections] = useState<Map<string, BLEConnection>>(new Map());
  const [isScanning, setIsScanning] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const eventHandlers = useRef<((event: BLEMotionEvent) => void)[]>([]);

  // 初期化: localStorage からタグを読み込み
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        setTags(parsed);
      } catch (e) {
        console.error('Failed to parse BLE tags from localStorage', e);
      }
    }
  }, []);

  // タグ変更時に localStorage に保存
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(tags));
  }, [tags]);

  /**
   * Web Bluetooth API が利用可能かチェック
   */
  const isBluetoothAvailable = useCallback(() => {
    if (!navigator.bluetooth) {
      setError('Web Bluetooth API is not supported in this browser.');
      return false;
    }
    return true;
  }, []);

  /**
   * BLE デバイスをスキャンしてペアリング
   */
  const scanAndPair = useCallback(async (): Promise<BLETag | null> => {
    if (!isBluetoothAvailable()) return null;

    setIsScanning(true);
    setError(null);

    try {
      // デバイス選択ダイアログを表示
      const device = await navigator.bluetooth.requestDevice({
        filters: [{ services: [BLE_SERVICE_UUID] }],
        optionalServices: [BLE_SERVICE_UUID],
      });

      if (!device.name) {
        throw new Error('Device name not available');
      }

      // GATT サーバーに接続
      const server = await device.gatt!.connect();
      const service = await server.getPrimaryService(BLE_SERVICE_UUID);
      const characteristic = await service.getCharacteristic(BLE_CHARACTERISTIC_UUID);

      // タグ情報を生成
      const tag: BLETag = {
        tag_id: device.id,
        name: device.name,
        mission_step_id: '', // 後で紐づけ
        device_id: device.id,
        last_seen: Date.now(),
      };

      // 接続を保存
      const connection: BLEConnection = {
        device,
        server,
        characteristic,
        tag,
      };

      setConnections((prev) => new Map(prev).set(tag.tag_id, connection));

      // Notify を開始
      await startNotifications(connection);

      // タグを登録
      setTags((prev) => [...prev, tag]);

      return tag;
    } catch (err: any) {
      console.error('BLE scan/pair failed:', err);
      setError(err.message || 'Failed to scan/pair BLE device');
      return null;
    } finally {
      setIsScanning(false);
    }
  }, [isBluetoothAvailable]);

  /**
   * Notify を開始してイベントを購読
   */
  const startNotifications = useCallback(
    async (connection: BLEConnection) => {
      const { characteristic, tag } = connection;

      try {
        await characteristic.startNotifications();

        characteristic.addEventListener('characteristicvaluechanged', (event: Event) => {
          const target = event.target as BluetoothRemoteGATTCharacteristic;
          const value = target.value;
          if (!value) return;

          // JSON パース
          const text = new TextDecoder().decode(value);
          try {
            const payload: BLEMotionEvent = JSON.parse(text);
            console.log('[BLE Event]', payload);

            // last_seen を更新
            setTags((prev) =>
              prev.map((t) =>
                t.tag_id === tag.tag_id ? { ...t, last_seen: Date.now() } : t
              )
            );

            // イベントハンドラーを呼び出し
            eventHandlers.current.forEach((handler) => handler(payload));
          } catch (err) {
            console.error('Failed to parse BLE event JSON:', text, err);
          }
        });

        console.log(`[BLE] Notifications started for ${tag.tag_id}`);
      } catch (err: any) {
        console.error('Failed to start notifications:', err);
        setError(err.message || 'Failed to start BLE notifications');
      }
    },
    []
  );

  /**
   * タグを削除
   */
  const removeTag = useCallback((tag_id: string) => {
    // 接続を切断
    const connection = connections.get(tag_id);
    if (connection) {
      connection.server.disconnect();
      setConnections((prev) => {
        const next = new Map(prev);
        next.delete(tag_id);
        return next;
      });
    }

    // タグを削除
    setTags((prev) => prev.filter((t) => t.tag_id !== tag_id));
  }, [connections]);

  /**
   * タグにステップを紐づけ
   */
  const linkTagToStep = useCallback((tag_id: string, mission_step_id: string) => {
    setTags((prev) =>
      prev.map((t) =>
        t.tag_id === tag_id ? { ...t, mission_step_id } : t
      )
    );
  }, []);

  /**
   * タグの名前を変更
   */
  const renameTag = useCallback((tag_id: string, name: string) => {
    setTags((prev) =>
      prev.map((t) => (t.tag_id === tag_id ? { ...t, name } : t))
    );
  }, []);

  /**
   * BLE イベントハンドラーを登録
   */
  const onBLEEvent = useCallback((handler: (event: BLEMotionEvent) => void) => {
    eventHandlers.current.push(handler);
    return () => {
      eventHandlers.current = eventHandlers.current.filter((h) => h !== handler);
    };
  }, []);

  /**
   * 既存のタグに再接続
   */
  const reconnectTag = useCallback(
    async (tag: BLETag): Promise<boolean> => {
      if (!isBluetoothAvailable()) return false;

      try {
        // デバイスを取得（既にペアリング済みの場合）
        const devices = await navigator.bluetooth.getDevices();
        const device = devices.find((d) => d.id === tag.device_id);

        if (!device) {
          console.warn(`Device ${tag.device_id} not found in paired devices`);
          return false;
        }

        // GATT サーバーに接続
        const server = await device.gatt!.connect();
        const service = await server.getPrimaryService(BLE_SERVICE_UUID);
        const characteristic = await service.getCharacteristic(BLE_CHARACTERISTIC_UUID);

        // 接続を保存
        const connection: BLEConnection = {
          device,
          server,
          characteristic,
          tag,
        };

        setConnections((prev) => new Map(prev).set(tag.tag_id, connection));

        // Notify を開始
        await startNotifications(connection);

        console.log(`[BLE] Reconnected to ${tag.tag_id}`);
        return true;
      } catch (err: any) {
        console.error(`Failed to reconnect to ${tag.tag_id}:`, err);
        setError(err.message || 'Failed to reconnect to BLE device');
        return false;
      }
    },
    [isBluetoothAvailable, startNotifications]
  );

  /**
   * すべてのタグに再接続を試みる
   */
  const reconnectAll = useCallback(async () => {
    for (const tag of tags) {
      if (!connections.has(tag.tag_id)) {
        await reconnectTag(tag);
      }
    }
  }, [tags, connections, reconnectTag]);

  return {
    tags,
    connections,
    isScanning,
    error,
    isBluetoothAvailable: isBluetoothAvailable(),
    scanAndPair,
    removeTag,
    linkTagToStep,
    renameTag,
    onBLEEvent,
    reconnectTag,
    reconnectAll,
  };
}
