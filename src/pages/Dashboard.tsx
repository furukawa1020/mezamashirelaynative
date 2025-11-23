import React, { useState } from 'react'
import usePageMeta from '../hooks/usePageMeta'
import { useAuth } from '../services/auth'
import Missions from './Missions'
import Groups from './Groups'
import { startSession } from '../services/localStore'
import DataManager from '../components/DataManager'
import { BLETagManager } from '../components/BLETagManager'
import { SessionManager } from '../components/SessionManager'
import { ScheduledAlarmManager } from '../components/ScheduledAlarmManager'
import { RelayNotification } from '../components/RelayNotification';
import { SensorDataViewer } from '../components/SensorDataViewer';
import { NotificationPermission } from '../components/NotificationPermission';

export default function Dashboard() {
  usePageMeta('ダッシュボード', '今日のセッションを確認・開始できます')
  const { user, signOut } = useAuth()
  const [view, setView] = useState<'home' | 'missions' | 'groups'>('home')

  const onStart = async () => {
    if (!user) return alert('ログインしてください')
    // 簡易: 最初の自分の mission を取得してセッション開始する流れにする
    try {
      // TODO: ここは本来ミッション選択UIにする
      const missionId = prompt('開始するミッションIDを入力（まずは作成してください）')
      if (!missionId) return
      const sid = await startSession(user.uid, missionId)
      alert('セッション開始: ' + sid)
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
          <div className="card" style={{ textAlign: 'center', padding: '40px 20px' }}>
            <div style={{ fontSize: 60, marginBottom: 10 }}>🌞</div>
            <h2 style={{ marginBottom: 10 }}>朝のリレー</h2>
            <p className="muted" style={{ marginBottom: 30 }}>次のタスクへバトンをつなごう</p>
            <button className="button" style={{ width: '100%', fontSize: 18, padding: 16 }} onClick={onStart}>
              今日のセッション開始
            </button>
          </div>

          <div style={{ marginTop: 20 }}>
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
