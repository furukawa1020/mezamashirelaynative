import React, { useState } from 'react'
import usePageMeta from '../hooks/usePageMeta'
import { useAuth } from '../services/auth'
import Missions from './Missions'
import Groups from './Groups'
import { startSession } from '../services/firestore'
import DataManager from '../components/DataManager'
import { BLETagManager } from '../components/BLETagManager'
import { SessionManager } from '../components/SessionManager'
import { ScheduledAlarmManager } from '../components/ScheduledAlarmManager'
import { RelayNotification } from '../components/RelayNotification';
import { SensorDataViewer } from '../components/SensorDataViewer';
import { NotificationPermission } from '../components/NotificationPermission';

export default function Dashboard(){
  usePageMeta('ダッシュボード','今日のセッションを確認・開始できます')
  const { user, signOut, sendAccountClaimLink } = useAuth()
  const [view, setView] = useState<'home'|'missions'|'groups'>('home')

  const onStart = async ()=>{
    if(!user) return alert('ログインしてください')
    // 簡易: 最初の自分の mission を取得してセッション開始する流れにする
    try{
      // TODO: ここは本来ミッション選択UIにする
      const missionId = prompt('開始するミッションIDを入力（まずは作成してください）')
      if(!missionId) return
      const sid = await startSession(user.uid, missionId)
      alert('セッション開始: ' + sid)
    }catch(e:any){
      alert('開始に失敗しました: '+e.message)
    }
  }

  return (
    <div className="container">
      <h2>ようこそ、{user?.displayName || user?.email}</h2>

      <nav style={{display:'flex',gap:12,marginBottom:12,flexWrap:'wrap'}}>
        <button className="button" onClick={()=>setView('home')}>ホーム</button>
        <button className="button" onClick={()=>setView('missions')}>ミッション</button>
        <button className="button" onClick={()=>setView('groups')}>グループ</button>
        <button className="button" onClick={onStart}>今日のセッション開始</button>
      </nav>

      {view==='home' && (
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
          <div className="card" style={{ marginTop: 16 }}>
            <h4>デバッグ: BLE/NFC ダミー</h4>
            <p>ダミーイベントを送信してステップ完了処理を検証できます。</p>
            <button className="button" onClick={()=>{
              window.dispatchEvent(new CustomEvent('mezamashi:step', { detail: { type:'manual', stepId:'debug-1' } }))
              alert('ダミーイベントを送信しました')
            }}>ダミー完了</button>
            <div style={{marginTop:12}}>
              <button className="button" onClick={async ()=>{
                const email = prompt('アカウントにするメールアドレスを入力してください')
                if(!email) return
                const ok = await sendAccountClaimLink(email)
                if(ok) alert('メールを送信しました。受信したリンクでアカウントを確定してください（同じ端末で開くと匿名データと紐付きます）')
                else alert('送信に失敗しました')
              }}>アカウントにする（メールで保存）</button>
            </div>
          </div>
        </div>
      )}

      {view==='missions' && <Missions />}
      {view==='groups' && <Groups />}
      
      <NotificationPermission />
    </div>
  )
}
