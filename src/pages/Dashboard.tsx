import React, { useState, useEffect } from 'react'
import usePageMeta from '../hooks/usePageMeta'
import { useAuth } from '../services/auth'
import Missions from './Missions'
import Groups from './Groups'
import { startSession, listMissions } from '../services/localStore'
import { SessionManager } from '../components/SessionManager'
import { ScheduledAlarmManager } from '../components/ScheduledAlarmManager'
import { RelayNotification } from '../components/RelayNotification'
import { NotificationPermission } from '../components/NotificationPermission'

export default function Dashboard() {
  usePageMeta('ダッシュボード', '今日のセッションを確認・開始できます')
  const { user } = useAuth()
  const [view, setView] = useState<'home' | 'missions' | 'groups'>('home')
  const [missions, setMissions] = useState<any[]>([])
  const [loadingMissions, setLoadingMissions] = useState(false)

  useEffect(() => {
    if (user && view === 'home') {
      setLoadingMissions(true)
      listMissions(user.uid)
        .then(setMissions)
        .catch(() => { })
        .finally(() => setLoadingMissions(false))
    }
  }, [user, view])

  const onStartSession = async (missionId: string) => {
    if (!user) {
      alert('ログインしてください')
      return
    }

    try {
      await startSession(user.uid, missionId)
      // SessionManager will automatically pick up the new session
    } catch (e: any) {
      alert('開始に失敗しました: ' + e.message)
    }
  }

  return (
    <div className="container">
      <header style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 24, marginBottom: 4 }}>おはよう、{user?.displayName || 'ゲスト'}</h1>
        <div className="small muted">今日の調子はどうですか？</div>
      </header>

      <div className="nav-tabs">
        <div className={`nav-tab ${view === 'home' ? 'active' : ''}`} onClick={() => setView('home')}>ホーム</div>
        <div className={`nav-tab ${view === 'missions' ? 'active' : ''}`} onClick={() => setView('missions')}>ミッション</div>
        <div className={`nav-tab ${view === 'groups' ? 'active' : ''}`} onClick={() => setView('groups')}>グループ</div>
      </div>

      {view === 'home' && (
        <div className="floating">
          {/* Mission Selection Cards - Sports Day Theme */}
          {missions.length > 0 && (
            <div style={{ marginBottom: 24 }}>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                marginBottom: 16,
                paddingLeft: 4
              }}>
                <span style={{ fontSize: 24 }}>🏃</span>
                <h3 style={{
                  margin: 0,
                  fontSize: 20,
                  fontWeight: 800,
                  color: '#1d1d1f',
                  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                  letterSpacing: '-0.02em'
                }}>
                  READY TO START?
                </h3>
              </div>

              <div style={{ display: 'grid', gap: 16 }}>
                {missions.map((mission, index) => {
                  const laneColors = ['#FF9500', '#34C759', '#007AFF', '#AF52DE', '#FF2D55'];
                  const accentColor = laneColors[index % laneColors.length];

                  return (
                    <div
                      key={mission.id}
                      role="button"
                      tabIndex={0}
                      aria-label={`${mission.name}を開始`}
                      className="card"
                      style={{
                        cursor: 'pointer',
                        transition: 'transform 0.1s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.1s',
                        border: 'none',
                        borderLeft: `6px solid ${accentColor}`,
                        borderRadius: 16,
                        padding: 20,
                        background: '#FFFFFF',
                        boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
                        position: 'relative',
                        overflow: 'hidden',
                        // Disable tap highlight on mobile
                        WebkitTapHighlightColor: 'transparent',
                        // Improve touch responsiveness
                        touchAction: 'manipulation',
                        // Prevent text selection on touch devices
                        WebkitUserSelect: 'none',
                        userSelect: 'none',
                      }}
                      onMouseEnter={e => {
                        e.currentTarget.style.transform = 'scale(0.99)'
                        e.currentTarget.style.boxShadow = '0 2px 10px rgba(0,0,0,0.04)'
                      }}
                      onMouseLeave={e => {
                        e.currentTarget.style.transform = 'scale(1)'
                        e.currentTarget.style.boxShadow = '0 4px 20px rgba(0,0,0,0.06)'
                      }}
                      onClick={() => onStartSession(mission.id)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault();
                          onStartSession(mission.id);
                        }
                      }}
                    >
                      {/* Track Lane Number Background */}
                      <div style={{
                        position: 'absolute',
                        right: -10,
                        bottom: -20,
                        fontSize: 120,
                        fontWeight: 900,
                        color: '#F2F2F7',
                        zIndex: 0,
                        fontFamily: 'Impact, sans-serif',
                        opacity: 0.5,
                        pointerEvents: 'none',
                      }}>
                        {index + 1}
                      </div>

                      <div style={{ position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16 }}>
                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div style={{
                            fontSize: 20,
                            fontWeight: 700,
                            marginBottom: 6,
                            color: '#1d1d1f',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                          }}>
                            {mission.name}
                          </div>
                          <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
                            <div style={{
                              fontSize: 14,
                              color: '#1d1d1f',
                              background: '#F2F2F7',
                              padding: '4px 10px',
                              borderRadius: 20,
                              fontWeight: 600,
                              display: 'flex',
                              alignItems: 'center',
                              gap: 4
                            }}>
                              ⏰ {mission.wake_time}
                            </div>

                            {mission.steps && mission.steps.length > 0 && (
                              <div style={{ display: 'flex', gap: 4 }}>
                                {mission.steps.slice(0, 3).map((step: any, idx: number) => (
                                  <span
                                    key={idx}
                                    style={{
                                      fontSize: 16,
                                    }}
                                    title={step.label}
                                  >
                                    {step.action_type === 'shake' && '👋'}
                                    {step.action_type === 'ai_detect' && '🤖'}
                                    {step.action_type === 'gps' && '📍'}
                                    {step.action_type === 'qr' && '📷'}
                                    {step.action_type === 'manual' && '👆'}
                                  </span>
                                ))}
                                {mission.steps.length > 3 && (
                                  <span style={{ fontSize: 12, color: '#86868b', alignSelf: 'center', fontWeight: 600 }}>
                                    +{mission.steps.length - 3}
                                  </span>
                                )}
                              </div>
                            )}
                          </div>
                        </div>
                        <div style={{
                          width: 48,
                          height: 48,
                          minWidth: 48,
                          borderRadius: '50%',
                          background: accentColor,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: 24,
                          color: 'white',
                          flexShrink: 0,
                          boxShadow: `0 4px 12px ${accentColor}66`,
                        }}>
                          ▶
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {missions.length === 0 && !loadingMissions && (
            <div className="card" style={{ textAlign: 'center', padding: '40px 20px' }}>
              <div style={{ fontSize: 60, marginBottom: 10 }}>🌞</div>
              <h2 style={{ marginBottom: 10 }}>朝のリレー</h2>
              <p className="muted" style={{ marginBottom: 20 }}>
                まずは「ミッション」タブでミッションを作成しましょう
              </p>
              <button
                className="button"
                style={{ padding: '12px 24px' }}
                onClick={() => setView('missions')}
              >
                ミッションを作成
              </button>
            </div>
          )}

          <div style={{ marginTop: 20 }}>
            <SessionManager />
            <RelayNotification />
            <ScheduledAlarmManager />
          </div>
        </div>
      )}

      {view === 'missions' && <Missions />}
      {view === 'groups' && <Groups />}

      <NotificationPermission />
    </div>
  )
}
