/**
 * SessionTimer - セッション経過時間とステップタイムの表示
 * 運動会風の競争演出を実現
 */

import React, { useEffect, useState } from 'react';

interface SessionTimerProps {
  session: any;
  steps: any[];
  targetTime?: number; // 目標タイム（秒）
}

export function SessionTimer({ session, steps, targetTime = 600 }: SessionTimerProps) {
  const [elapsedSeconds, setElapsedSeconds] = useState(0);

  useEffect(() => {
    if (!session || session.status !== 'in_progress') {
      setElapsedSeconds(0);
      return;
    }

    // 経過時間を計算
    const updateElapsed = () => {
      const now = Date.now();
      const startTime = session.started_at || now;
      const elapsed = Math.floor((now - startTime) / 1000);
      setElapsedSeconds(elapsed);
    };

    updateElapsed();
    const interval = setInterval(updateElapsed, 100); // 100ms ごとに更新

    return () => clearInterval(interval);
  }, [session]);

  if (!session || session.status !== 'in_progress') {
    return null;
  }

  const minutes = Math.floor(elapsedSeconds / 60);
  const seconds = elapsedSeconds % 60;
  const progress = Math.min((elapsedSeconds / targetTime) * 100, 100);
  const isOverTime = elapsedSeconds > targetTime;

  // 完了したステップ数
  const completedCount = steps.filter((s) => s.result === 'success').length;
  const totalCount = steps.length;

  return (
    <div style={{
      padding: 20,
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      borderRadius: 16,
      color: 'white',
      marginBottom: 16,
      boxShadow: '0 8px 24px rgba(0,0,0,0.15)',
    }}>
      {/* メインタイマー */}
      <div style={{ textAlign: 'center', marginBottom: 16 }}>
        <div style={{ fontSize: 14, opacity: 0.9, marginBottom: 8 }}>経過時間</div>
        <div style={{
          fontSize: 56,
          fontWeight: 700,
          fontFamily: 'monospace',
          letterSpacing: 2,
          color: isOverTime ? '#ff6b6b' : 'white',
        }}>
          {String(minutes).padStart(2, '0')}:{String(seconds).padStart(2, '0')}
        </div>
      </div>

      {/* 進捗バー */}
      <div style={{ marginBottom: 12 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
          <span>進捗</span>
          <span>{completedCount} / {totalCount} ステップ</span>
        </div>
        <div style={{
          height: 8,
          background: 'rgba(255,255,255,0.3)',
          borderRadius: 4,
          overflow: 'hidden',
        }}>
          <div style={{
            height: '100%',
            width: `${(completedCount / totalCount) * 100}%`,
            background: 'linear-gradient(90deg, #4ade80 0%, #22c55e 100%)',
            transition: 'width 0.3s ease',
          }} />
        </div>
      </div>

      {/* 目標タイム比較 */}
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, opacity: 0.95 }}>
        <div>
          目標: {Math.floor(targetTime / 60)}:{String(targetTime % 60).padStart(2, '0')}
        </div>
        <div style={{ fontWeight: 600 }}>
          {isOverTime ? (
            <span style={{ color: '#ff6b6b' }}>
              ⚠️ +{Math.floor((elapsedSeconds - targetTime) / 60)}:{String((elapsedSeconds - targetTime) % 60).padStart(2, '0')}
            </span>
          ) : (
            <span style={{ color: '#4ade80' }}>
              ✓ -{Math.floor((targetTime - elapsedSeconds) / 60)}:{String((targetTime - elapsedSeconds) % 60).padStart(2, '0')}
            </span>
          )}
        </div>
      </div>

      {/* タイムバー */}
      <div style={{
        marginTop: 12,
        height: 6,
        background: 'rgba(255,255,255,0.2)',
        borderRadius: 3,
        overflow: 'hidden',
      }}>
        <div style={{
          height: '100%',
          width: `${progress}%`,
          background: isOverTime ? '#ff6b6b' : '#4ade80',
          transition: 'width 0.1s linear',
        }} />
      </div>
    </div>
  );
}
