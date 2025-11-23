import React, { useEffect, useState } from 'react'
import { useAuth } from '../services/auth'
import { createMission, listMissions, createMissionStep, listMissionSteps, deleteMission, deleteMissionStep } from '../services/localStore'
import usePageMeta from '../hooks/usePageMeta'
import Skeleton from '../components/Skeleton'

export default function Missions() {
  usePageMeta('ミッション一覧', 'ミッションを作成・編集して朝のタスクを共有しましょう')
  const { user } = useAuth()
  const [missions, setMissions] = useState<any[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [name, setName] = useState('')
  const [wakeTime, setWakeTime] = useState('07:00')

  useEffect(() => {
    if (!user) return
    setLoading(true)
    listMissions(user.uid).then(setMissions).catch(() => { }).finally(() => setLoading(false))
  }, [user])

  const loadSteps = async (missionId: string) => {
    const s = await listMissionSteps(missionId)
    setMissions(prev => prev.map(m => m.id === missionId ? { ...m, steps: s } : m))
  }

  const add = async () => {
    if (!user) return
    await createMission(user.uid, { name, wake_time: wakeTime })
    setName('')
    const updated = await listMissions(user.uid)
    setMissions(updated)
  }

  const remove = async (id: string) => {
    if (!confirm('本当に削除しますか？')) return
    await deleteMission(id)
    const updated = await listMissions(user?.uid || '')
    setMissions(updated)
  }

  const addStep = async (missionId: string) => {
    const label = prompt('ステップ名を入力')
    if (!label) return

    // Ask for type
    const typeStr = prompt('タイプを選択:\n1: 手動 (Manual)\n2: シェイク (Shake)\n3: QRコード (QR)\n4: AI物体認識 (AI)\n5: GPS移動 (GPS)', '1')
    let action_type: 'manual' | 'shake' | 'qr' | 'gps' | 'ai_detect' = 'manual'
    let action_config: any = {}

    if (typeStr === '2') {
      action_type = 'shake'
      const count = prompt('シェイク回数は？', '20')
      action_config = { count: parseInt(count || '20') }
    } else if (typeStr === '3') {
      action_type = 'qr'
      const val = prompt('正解のQR/バーコード値は？(空欄なら何でもOK)', '')
      action_config = { targetValue: val }
    } else if (typeStr === '4') {
      action_type = 'ai_detect'
      const target = prompt('検出する物体は？(例: cup, bottle, person, cell phone)', 'cup')
      action_config = { targetLabel: target || 'cup' }
    } else if (typeStr === '5') {
      action_type = 'gps'
      const dist = prompt('移動距離(m)は？', '100')
      action_config = { distance: parseInt(dist || '100') }
    }

    // 既存のステップを取得して、次の order を決定
    const currentSteps = await listMissionSteps(missionId)
    const nextOrder = currentSteps.length > 0 ? Math.max(...currentSteps.map(s => s.order || 0)) + 1 : 1

    await createMissionStep(missionId, { label, order: nextOrder, action_type, action_config })
    await loadSteps(missionId)
  }

  const removeStep = async (missionId: string, stepId: string) => {
    if (!confirm('ステップを削除しますか？')) return
    await deleteMissionStep(stepId)
    await loadSteps(missionId)
  }

  return (
    <div className="floating">
      <div className="card">
        <h3>新しいミッション</h3>
        <label className="small muted">ミッション名</label>
        <input className="input" value={name} onChange={e => setName(e.target.value)} placeholder="例: 朝のルーティン" />
        <label className="small muted">起床時間</label>
        <input className="input" type="time" value={wakeTime} onChange={e => setWakeTime(e.target.value)} />
        <div style={{ marginTop: 12, textAlign: 'right' }}>
          <button className="button" onClick={add}>作成する</button>
        </div>
      </div>

      <h3 style={{ marginLeft: 8, marginBottom: 12 }}>マイミッション</h3>
      {loading ? (
        <div className="card"><Skeleton lines={3} /></div>
      ) : missions.length === 0 ? (
        <div className="card" style={{ textAlign: 'center', color: '#666' }}>
          ミッションがありません。<br />新しいミッションを作成しましょう。
        </div>
      ) : (
        missions.map(m => (
          <div key={m.id} className="card" style={{ position: 'relative' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
              <div>
                <div style={{ fontSize: 18, fontWeight: 'bold' }}>{m.name}</div>
                <div className="small muted">⏰ {m.wake_time} 起床</div>
              </div>
              <button className="button" style={{ background: 'var(--danger)', padding: '6px 12px', fontSize: 12 }} onClick={() => remove(m.id)}>削除</button>
            </div>

            <div style={{ background: '#2c2c2e', borderRadius: 8, padding: 12 }}>
              <div style={{ marginBottom: 8, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span className="small muted">ステップ一覧</span>
                <button className="button" style={{ padding: '4px 8px', fontSize: 12, background: '#3a3a3c' }} onClick={() => addStep(m.id)}>+ 追加</button>
              </div>
              {(m.steps || []).length === 0 && <div className="small muted" style={{ textAlign: 'center' }}>ステップがありません</div>}
              {(m.steps || []).map((s: any) => (
                <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: '1px solid #3a3a3c' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ width: 20, height: 20, borderRadius: '50%', background: '#0a84ff', color: 'white', fontSize: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{s.order}</div>
                    <div>
                      <div>{s.label}</div>
                      <div className="small muted" style={{ fontSize: 10 }}>
                        {s.action_type === 'shake' && `👋 シェイク (${s.action_config?.count}回)`}
                        {s.action_type === 'qr' && `📷 QRスキャン`}
                        {s.action_type === 'ai_detect' && `🤖 AI検出 (${s.action_config?.targetLabel})`}
                        {s.action_type === 'gps' && `📍 GPS移動 (${s.action_config?.distance}m)`}
                        {s.action_type === 'manual' && `👆 手動`}
                      </div>
                    </div>
                  </div>
                  <button style={{ background: 'none', border: 'none', color: '#ff453a', cursor: 'pointer', fontSize: 18 }} onClick={() => removeStep(m.id, s.id)}>×</button>
                </div>
              ))}
            </div>
          </div>
        ))
      )}
    </div>
  )
}
