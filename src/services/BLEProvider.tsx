/**
 * BLEProvider - BLE 接続とイベント処理を管理するコンテキスト
 */

import React, { createContext, useContext, useEffect, useCallback } from 'react';
import { useBLE } from '../hooks/useBLE';
import { BLEMotionEvent } from '../types/ble';
import { completeSessionStep, listSessionSteps } from '../services/firestore';
import { useAuth } from '../services/auth';
import { useToast } from '../components/Toast';
import { useSound, playSuccess } from '../services/soundProvider';

interface BLEContextValue {
  tags: ReturnType<typeof useBLE>['tags'];
  connections: ReturnType<typeof useBLE>['connections'];
  isScanning: boolean;
  error: string | null;
  isBluetoothAvailable: boolean;
  scanAndPair: ReturnType<typeof useBLE>['scanAndPair'];
  removeTag: ReturnType<typeof useBLE>['removeTag'];
  linkTagToStep: ReturnType<typeof useBLE>['linkTagToStep'];
  renameTag: ReturnType<typeof useBLE>['renameTag'];
  reconnectAll: ReturnType<typeof useBLE>['reconnectAll'];
}

const BLEContext = createContext<BLEContextValue | null>(null);

export function BLEProvider({ children }: { children: React.ReactNode }) {
  const ble = useBLE();
  const { user } = useAuth();
  const { showToast } = useToast();
  const { muted } = useSound();

  /**
   * BLE イベントを受信してセッションステップを完了
   */
  const handleBLEEvent = useCallback(
    async (event: BLEMotionEvent) => {
      console.log('[BLEProvider] Received event:', event);

      // やったフリは無視
      if (event.event === 'FALSE') {
        showToast('⚠️ やったフリを検出しました');
        return;
      }

      // タグを検索
      const tag = ble.tags.find((t) => t.tag_id === event.tag_id);
      if (!tag) {
        console.warn(`Tag ${event.tag_id} not found in registered tags`);
        return;
      }

      // ステップが紐づいていない
      if (!tag.mission_step_id) {
        console.warn(`Tag ${event.tag_id} has no linked mission_step_id`);
        showToast('タグにステップが紐づいていません');
        return;
      }

      // ユーザーが未ログイン
      if (!user) {
        console.warn('User not logged in');
        return;
      }

      try {
        // 今日のセッションステップを検索
        const allSteps = await listSessionSteps(''); // 全セッション（簡易実装）
        const targetStep = allSteps.find(
          (s) =>
            s.step_id === tag.mission_step_id &&
            s.result === 'pending'
        );

        if (!targetStep) {
          console.warn(`No pending session_step found for step_id=${tag.mission_step_id}`);
          showToast('該当するステップが見つかりません');
          return;
        }

        // ステップを完了
        await completeSessionStep(targetStep.id, {
          ble_tag_id: event.tag_id,
          ble_event: event.event,
          ble_confidence: event.confidence,
          duration_ms: event.duration_ms,
        });

        console.log(`[BLE] Completed session_step ${targetStep.id}`);
        showToast(`✅ ${tag.name} で完了しました`);
        if (!muted) playSuccess();

        // バイブレーション
        if (navigator.vibrate) {
          navigator.vibrate(200);
        }
      } catch (err: any) {
        console.error('[BLE] Failed to complete session_step:', err);
        // エラーメッセージを表示（順番チェックのエラーなど）
        showToast(err.message || 'ステップの完了に失敗しました');
      }
    },
    [ble.tags, user, showToast, playSuccess]
  );

  // BLE イベントハンドラーを登録
  useEffect(() => {
    const unsubscribe = ble.onBLEEvent(handleBLEEvent);
    return unsubscribe;
  }, [ble, handleBLEEvent]);

  // 初期化時にすべてのタグに再接続を試みる
  useEffect(() => {
    if (ble.tags.length > 0) {
      ble.reconnectAll();
    }
  }, []); // 初回のみ

  const value: BLEContextValue = {
    tags: ble.tags,
    connections: ble.connections,
    isScanning: ble.isScanning,
    error: ble.error,
    isBluetoothAvailable: ble.isBluetoothAvailable,
    scanAndPair: ble.scanAndPair,
    removeTag: ble.removeTag,
    linkTagToStep: ble.linkTagToStep,
    renameTag: ble.renameTag,
    reconnectAll: ble.reconnectAll,
  };

  return <BLEContext.Provider value={value}>{children}</BLEContext.Provider>;
}

export function useBLEContext() {
  const ctx = useContext(BLEContext);
  if (!ctx) {
    throw new Error('useBLEContext must be used within BLEProvider');
  }
  return ctx;
}
