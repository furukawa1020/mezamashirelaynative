/**
 * NotificationPermission - 通知権限リクエスト
 * アラームを確実に鳴らすために必要
 */

import React, { useEffect, useState } from 'react';

export function NotificationPermission() {
  const [needsPermission, setNeedsPermission] = useState(false);

  useEffect(() => {
    // 通知APIがサポートされているかチェック
    if ('Notification' in window) {
      if (Notification.permission === 'default') {
        setNeedsPermission(true);
      }
    }
  }, []);

  const requestPermission = async () => {
    if ('Notification' in window) {
      const permission = await Notification.requestPermission();
      if (permission === 'granted') {
        setNeedsPermission(false);
        // テスト通知
        new Notification('通知が有効になりました', {
          body: 'アラームが正常に動作します',
        });
      }
    }
  };

  if (!needsPermission) return null;

  return (
    <div
      style={{
        position: 'fixed',
        bottom: 80,
        left: 16,
        right: 16,
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white',
        padding: 16,
        borderRadius: 12,
        boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
        zIndex: 1000,
      }}
    >
      <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 8 }}>
        🔔 通知を有効にしてください
      </div>
      <div style={{ fontSize: 14, marginBottom: 12, opacity: 0.9 }}>
        アラームが確実に鳴るように、通知権限が必要です
      </div>
      <button
        onClick={requestPermission}
        style={{
          width: '100%',
          padding: '12px 24px',
          background: 'white',
          color: '#667eea',
          border: 'none',
          borderRadius: 8,
          fontSize: 15,
          fontWeight: 600,
          cursor: 'pointer',
        }}
      >
        許可する
      </button>
    </div>
  );
}
