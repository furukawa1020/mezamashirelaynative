import React, { useEffect, useState } from 'react';
import { useAuth } from '../services/auth';
import { listTodaySessionsByUser, listSessionSteps, startSession, listMissions, completeSessionStep } from '../services/localStore';
import { useAlarm } from '../services/AlarmProvider';
import StepItem from '../components/StepItem';
import { SessionTimer } from '../components/SessionTimer';
import AICamera from './sensors/AICamera';
import QRScanner from './sensors/QRScanner';
import { useMotion } from '../hooks/useMotion';
import { useGeolocation } from '../hooks/useGeolocation';

export function SessionManager() {
  const { user } = useAuth();
  const { isPlaying, startAlarm, stopAlarm, volume, setVolume } = useAlarm();
  const [sessions, setSessions] = useState<any[]>([]);
  const [currentSession, setCurrentSession] = useState<any | null>(null);
  const [steps, setSteps] = useState<any[]>([]);
  const [missions, setMissions] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  // Sensor hooks
  const { shakeCount, resetCount } = useMotion();
  const { location, getDistanceFrom } = useGeolocation();
  const [initialLocation, setInitialLocation] = useState<GeolocationCoordinates | null>(null);

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
    if (!user) return [];
    const s = await listTodaySessionsByUser(user.uid);
    setSessions(s);

    // 進行中のセッションがあれば自動選択
    const active = s.find((x: any) => x.status === 'in_progress');
    if (active) {
      setCurrentSession(active);
      loadSteps(active.id);
    }
    return s;
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
      const updatedSessions = await loadSessions(); // Get fresh list
      const newSession = updatedSessions.find((s: any) => s.id === sid);

      if (newSession) {
        setCurrentSession(newSession);
        await loadSteps(sid);
        startAlarm(); // アラーム開始

        // GPS初期位置保存
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(pos => setInitialLocation(pos.coords));
        }
      }
    } catch (e: any) {
      alert('セッション開始に失敗: ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  // ステップ完了時に再読み込み
  const handleStepComplete = React.useCallback(async () => {
    if (currentSession) {
      await loadSteps(currentSession.id);
      resetCount(); // Shake count reset
    }
  }, [currentSession, resetCount]);

  const completeStep = React.useCallback(async (stepId: string) => {
    await completeSessionStep(stepId);
    // handleStepComplete is called via event listener or directly?
    // In the original code, it was called directly.
    if (currentSession) {
      await loadSteps(currentSession.id);
      resetCount();
    }
  }, [currentSession, resetCount]);

  // Active Step Logic
  const activeStep = steps.find(s => s.result !== 'success');

  // Shake Logic
  useEffect(() => {
    if (activeStep?.action_type === 'shake') {
      const target = activeStep.action_config?.count || 20;
      if (shakeCount >= target) {
        completeStep(activeStep.id);
      }
    }
  }, [shakeCount, activeStep]);

  // GPS Logic
  useEffect(() => {
    if (activeStep?.action_type === 'gps' && initialLocation && location) {
      const targetDist = activeStep.action_config?.distance || 100;
      const dist = getDistanceFrom(initialLocation.latitude, initialLocation.longitude);
      if (dist && dist >= targetDist) {
        completeStep(activeStep.id);
      }
    }
  }, [location, activeStep, initialLocation]);

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
      {currentSession && currentSession.status === 'in_progress' && (
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
          {/* Active Challenge Area */}
          {activeStep && (
            <div style={{ marginBottom: 20, padding: 16, background: 'white', borderRadius: 12, boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}>
              <h4 style={{ marginTop: 0, textAlign: 'center' }}>🔥 現在のチャレンジ: {activeStep.label}</h4>

              {activeStep.action_type === 'ai_detect' && (
                <AICamera
                  targetLabel={activeStep.action_config?.targetLabel || 'cup'}
                  onDetected={() => completeStep(activeStep.id)}
                />
              )}

              {activeStep.action_type === 'qr' && (
                <QRScanner
                  onScan={(val) => {
                    const target = activeStep.action_config?.targetValue;
                    if (!target || val === target) {
                      completeStep(activeStep.id);
                    } else {
                      alert('違うQRコードです！');
                    }
                  }}
                />
              )}

              {activeStep.action_type === 'shake' && (
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 48 }}>👋</div>
                  <p>スマホを振ってください！</p>
                  <div style={{ fontSize: 24, fontWeight: 'bold' }}>{shakeCount} / {activeStep.action_config?.count || 20}</div>
                  <progress value={shakeCount} max={activeStep.action_config?.count || 20} style={{ width: '100%' }} />
                </div>
              )}

              {activeStep.action_type === 'gps' && (
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 48 }}>🏃</div>
                  <p>移動してください！</p>
                  <div style={{ fontSize: 24, fontWeight: 'bold' }}>
                    {initialLocation && location
                      ? Math.round(getDistanceFrom(initialLocation.latitude, initialLocation.longitude) || 0)
                      : 0}m / {activeStep.action_config?.distance || 100}m
                  </div>
                </div>
              )}

              {activeStep.action_type === 'manual' && (
                <div style={{ textAlign: 'center' }}>
                  <button className="button" onClick={() => completeStep(activeStep.id)}>完了！</button>
                </div>
              )}
            </div>
          )}

          {/* ステップ一覧 */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {steps.map((step) => (
              <StepItem
                key={step.id}
                step={step}
                onComplete={() => completeStep(step.id)}
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
