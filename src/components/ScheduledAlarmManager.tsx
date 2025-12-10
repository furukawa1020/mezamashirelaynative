/**
 * ScheduledAlarmManager - 時刻指定アラーム管理
 * ミッションの wake_time に基づいて自動的にアラームとセッションを開始
 */

import React, { useEffect, useState } from 'react';

import { listMissions, startSession } from '../services/localStore';
import { useAlarm } from '../services/AlarmProvider';
import { useToast } from '../components/Toast';
import { IconBell } from './Icons';

interface ScheduledAlarmManagerProps {
  user: any;
}

export function ScheduledAlarmManager({ user }: ScheduledAlarmManagerProps) {
  // const { user } = useAuth(); // Removed to avoid ReferenceError
  const { startAlarm } = useAlarm();
  const { showToast } = useToast();
  const [nextAlarm, setNextAlarm] = useState<{ time: string; missionId: string; missionName: string } | null>(null);

  useEffect(() => {
    if (!user) return;

    const checkAlarms = async () => {
      const missions = await listMissions(user.uid);
      const now = new Date();
      const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
      const todayKey = now.toISOString().split('T')[0]; // YYYY-MM-DD

      // 今日のアラーム時刻を持つミッションを探す
      for (const mission of missions) {
        if (mission.wake_time === currentTime) {
          // 既にこのミッションで今日セッションを開始済みかチェック
          const alreadyTriggeredKey = `mz_alarm_triggered_${mission.id}_${todayKey}`;
          if (localStorage.getItem(alreadyTriggeredKey)) {
            console.log(`[ScheduledAlarm] Already triggered today for mission: ${mission.name}`);
            continue; // 重複起動を防ぐ
          }

          // アラーム時刻に到達！
          console.log(`[ScheduledAlarm] Triggering alarm for mission: ${mission.name}`);

          try {
            // セッション開始
            const sessionId = await startSession(user.uid, mission.id);
            console.log(`[ScheduledAlarm] Session started: ${sessionId}`);

            // アラーム開始
            startAlarm();

            // 通知
            showToast(`${mission.name} のアラームが鳴りました！`);

            // バイブレーション
            if (navigator.vibrate) {
              navigator.vibrate([200, 100, 200, 100, 200]);
            }

            // 今日は既に起動済みとマーク（翌日まで有効）
            localStorage.setItem(alreadyTriggeredKey, 'true');

            // リロードせずに状態を更新（Dashboard が再レンダリングされてセッションが表示される）
          } catch (e: any) {
            console.error('[ScheduledAlarm] Failed to start session:', e);
            showToast('セッション開始に失敗しました');
          }

          break; // 1つのミッションだけ処理
        }
      }

      // 次のアラーム時刻を表示
      const upcomingMissions = missions
        .filter((m: any) => m.wake_time > currentTime)
        .sort((a: any, b: any) => a.wake_time.localeCompare(b.wake_time));

      if (upcomingMissions.length > 0) {
        const next = upcomingMissions[0];
        setNextAlarm({
          time: next.wake_time,
          missionId: next.id,
          missionName: next.name,
        });
      } else {
        setNextAlarm(null);
      }
    };

    // 初回チェック
    checkAlarms();

    // 1分ごとにチェック
    const interval = setInterval(checkAlarms, 60000);

    return () => clearInterval(interval);
  }, [user, startAlarm, showToast]);

  if (!nextAlarm) return null;

  return (
    <div style={{ padding: 12, background: '#e3f2fd', borderRadius: 8, marginBottom: 16 }}>
      <div style={{ fontSize: 13, color: '#1976d2', fontWeight: 500 }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
          <IconBell size={14} /> 次のアラーム: {nextAlarm.time} — {nextAlarm.missionName}
        </span>
      </div>
    </div>
  );
}
