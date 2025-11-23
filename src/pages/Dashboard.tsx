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
      <h2>ようこそ、{user?.displayName || user?.email}</h2>

      <nav style={{ display: 'flex', gap: 12, marginBottom: 12, flexWrap: 'wrap' }}>
        <button className="button" onClick={() => setView('home')}>ホーム</button>
        <button className="button" onClick={() => setView('missions')}>ミッション</button>
        <button className="button" onClick={() => setView('groups')}>グループ</button>
        <button className="button" onClick={onStart}>今日のセッション開始</button>
      </nav>

      {view === 'home' && (
        <div className="card">
          <RelayNotification />
          <ScheduledAlarmManager />
          <SessionManager />
          <div style={{ marginTop: 16 }}>
            <BLETagManager />
          </div>
          <SensorDataViewer />
          <div style={{ marginTop: 16 }}>
            <DataManager />
          </div>
        </div>
      )}

      {view === 'missions' && <Missions />}
      {view === 'groups' && <Groups />}

      <NotificationPermission />
    </div>
  )
}
