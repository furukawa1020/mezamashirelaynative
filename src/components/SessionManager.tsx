/**
 * SessionManager - セッション管理とアラーム制御
 * セッション開始時にアラームを開始し、全ステップ完了時に停止
 */

import React, { useEffect, useState } from 'react';
import { useAuth } from '../services/auth';
import { listTodaySessionsByUser, listSessionSteps, startSession, listMissions } from '../services/localStore';
import { useAlarm } from '../services/AlarmProvider';
import StepItem from '../components/StepItem';
import { SessionTimer } from '../components/SessionTimer';

export function SessionManager() {
  const { user } = useAuth();
  const { isPlaying, startAlarm, stopAlarm, volume, setVolume } = useAlarm();
  const [sessions, setSessions] = useState<any[]>([]);
  const [currentSession, setCurrentSession] = useState<any | null>(null);
  const [steps, setSteps] = useState<any[]>([]);
  const [missions, setMissions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  // ミッション読み込み
  useEffect(() => {
    if (!user) return;
    (async () => {
      const m = await listMissions(user.uid);
      setMissions(m);
    })();
  }, [user]);

  // 今日のセッションを読み込み
  const loadSessions = async () => {
    if (!user) return;
    const s = await listTodaySessionsByUser(user.uid);
    setSessions(s);

    // 進行中のセッションがあれば自動選択
    const active = s.find((x: any) => x.status === 'started');
    if (active) {
      setCurrentSession(active);
      loadSteps(active.id);
    }
  };

  useEffect(() => {
    loadSessions();
  }, [user]);

  // ステップ読み込み
  const loadSteps = async (sessionId: string) => {
    const st = await listSessionSteps(sessionId);
    setSteps(st);

    // 全ステップ完了チェック
    const allCompleted = st.every((s: any) => s.result === 'success');
    if (allCompleted && isPlaying) {
      stopAlarm();
    }
  };

  // セッション開始
  const handleStartSession = async (missionId: string) => {
    if (!user) return;
    setLoading(true);
    try {
      const sid = await startSession(user.uid, missionId);
      await loadSessions();
      const newSession = sessions.find((s: any) => s.id === sid);
      if (newSession) {
        setCurrentSession(newSession);
        await loadSteps(sid);
        startAlarm(); // アラーム開始
      }
    } catch (e: any) {
      alert('セッション開始に失敗: ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  // ステップ完了時に再読み込み
  const handleStepComplete = async () => {
    if (currentSession) {
      await loadSteps(currentSession.id);
    }
  };

  useEffect(() => {
    window.addEventListener('mezamashi:step-complete', handleStepComplete);
    return () => window.removeEventListener('mezamashi:step-complete', handleStepComplete);
  }, [currentSession]);

  return (
    <div style={{ padding: 16, background: '#f5f5f7', borderRadius: 12 }}>
      <h3 style={{ margin: '0 0 16px 0', fontSize: 18, fontWeight: 600 }}>
        今日のセッション {isPlaying && <span style={{ color: '#ff3b30' }}>🔔 アラーム鳴動中</span>}
      </h3>

      {/* タイマー表示（セッション実行中） */}
      {currentSession && currentSession.status === 'started' && (
        <SessionTimer session={currentSession} steps={steps} targetTime={600} />
      )}

      {/* アラーム音量調整 */}
      {isPlaying && (
        <div style={{ marginBottom: 16, padding: 12, background: '#fff3cd', borderRadius: 8 }}>
          <label style={{ display: 'block', fontSize: 14, marginBottom: 4 }}>
            音量: {Math.round(volume * 100)}%
          </label>
          <input
            type="range"
            min="0"
            max="1"
            step="0.1"
            value={volume}
            onChange={(e) => setVolume(parseFloat(e.target.value))}
            style={{ width: '100%' }}
          />
          <button
            onClick={stopAlarm}
            style={{
              marginTop: 8,
              padding: '6px 12px',
              background: '#ff3b30',
              color: 'white',
              border: 'none',
              borderRadius: 6,
              fontSize: 14,
              cursor: 'pointer',
            }}
          >
            アラームを停止
          </button>
        </div>
      )}

      {/* セッション開始 */}
      {!currentSession && (
        <div style={{ marginBottom: 16 }}>
          <p style={{ margin: '0 0 8px 0', fontSize: 14 }}>ミッションを選んでセッションを開始:</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {missions.map((mission) => (
              <button
                key={mission.id}
                onClick={() => handleStartSession(mission.id)}
                disabled={loading}
                style={{
                  padding: '10px 16px',
                  background: loading ? '#ccc' : '#007aff',
                  color: 'white',
                  border: 'none',
                  borderRadius: 8,
                  fontSize: 14,
                  fontWeight: 500,
                  cursor: loading ? 'not-allowed' : 'pointer',
                  textAlign: 'left',
                }}
              >
                {mission.name} ({mission.wake_time})
              </button>
            ))}
          </div>
          {missions.length === 0 && (
            <p style={{ margin: 0, color: '#666', fontSize: 14 }}>
              ミッションがありません。先に「ミッション」タブで作成してください。
            </p>
          )}
        </div>
      )}

      {/* 進行中のセッション */}
      {currentSession && (
        <div>
          <div style={{ marginBottom: 12, padding: 12, background: 'white', borderRadius: 8 }}>
            <strong style={{ fontSize: 16 }}>進行中のセッション</strong>
            <p style={{ margin: '4px 0 0 0', fontSize: 14, color: '#666' }}>
              開始: {new Date(currentSession.started_at).toLocaleTimeString('ja-JP')}
            </p>
          </div>

          {/* ステップ一覧 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {steps.map((step) => (
              <StepItem
                key={step.id}
                step={step}
                onComplete={() => handleStepComplete()}
              />
            ))}
          </div>

          {steps.every((s) => s.result === 'success') && (
            <div style={{ marginTop: 16, padding: 12, background: '#d4edda', borderRadius: 8 }}>
              <p style={{ margin: 0, color: '#155724', fontSize: 14, fontWeight: 600 }}>
                🎉 すべてのステップが完了しました！
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
