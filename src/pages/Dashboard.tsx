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
          {/* Mission Selection Cards */}
          {missions.length > 0 && (
            <div style={{ marginBottom: 20 }}>
              <h3 style={{ marginLeft: 8, marginBottom: 12 }}>ミッションを選択</h3>
              <div style={{ display: 'grid', gap: 12 }}>
                {missions.map(mission => (
                  <div
                    key={mission.id}
                    role="button"
                    tabIndex={0}
                    aria-label={`${mission.name}を開始`}
                    className="card"
                    style={{
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      border: '2px solid transparent',
                      // Disable tap highlight on mobile
                      WebkitTapHighlightColor: 'transparent',
                      // Improve touch responsiveness
                      touchAction: 'manipulation',
                      // Prevent text selection on touch devices
                      WebkitUserSelect: 'none',
                      userSelect: 'none',
                    }}
                    onMouseEnter={e => {
                      e.currentTarget.style.borderColor = '#0a84ff'
                      e.currentTarget.style.transform = 'translateY(-2px)'
                    }}
                    onMouseLeave={e => {
                      e.currentTarget.style.borderColor = 'transparent'
                      e.currentTarget.style.transform = 'translateY(0)'
                    }}
                    onClick={() => onStartSession(mission.id)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        onStartSession(mission.id);
                      }
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{
                          fontSize: 18,
                          fontWeight: 600,
                          marginBottom: 4,
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                        }}>
                          {mission.name}
                        </div>
                        <div style={{ fontSize: 13, color: '#9ca3af', marginBottom: 8 }}>
                          ⏰ {mission.wake_time} 起床
                        </div>
                        {mission.steps && mission.steps.length > 0 && (
                          <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                            {mission.steps.slice(0, 3).map((step: any, idx: number) => (
                              <span
                                key={idx}
                                style={{
                                  fontSize: 11,
                                  padding: '2px 6px',
                                  background: '#374151',
                                  borderRadius: 4,
                                  color: '#d1d5db',
                                  whiteSpace: 'nowrap',
                                }}
                              >
                                {step.action_type === 'shake' && '👋'}
                                {step.action_type === 'ai_detect' && '🤖'}
                                {step.action_type === 'gps' && '📍'}
                                {step.action_type === 'qr' && '📷'}
                                {step.action_type === 'manual' && '👆'}
                                {' '}{step.label}
                              </span>
                            ))}
                            {mission.steps.length > 3 && (
                              <span style={{ fontSize: 11, color: '#9ca3af' }}>
                                +{mission.steps.length - 3}
                              </span>
                            )}
                          </div>
                        )}
                      </div>
                      <div style={{
                        width: 40,
                        height: 40,
                        minWidth: 40,
                        borderRadius: '50%',
                        background: '#0a84ff',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: 20,
                        flexShrink: 0,
                      }}>
                        ▶
                      </div>
                    </div>
                  </div>
                ))}
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
