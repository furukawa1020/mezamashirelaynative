import React, { useEffect, useState } from 'react'
import React, { useEffect, useState } from 'react'
import { createMission, listMissions, createMissionStep, listMissionSteps, deleteMission, deleteMissionStep } from '../services/localStore'
import usePageMeta from '../hooks/usePageMeta'
import Skeleton from '../components/Skeleton'
import { Modal } from '../components/Modal'
import { StepTypeSelector } from '../components/StepTypeSelector'
import { IconShake, IconScan, IconMapPin, IconQRCode, IconTouch, IconAlarm } from '../components/Icons'

interface MissionsProps {
  user: any;
}

export default function Missions({ user }: MissionsProps) {
  usePageMeta('ミッション一覧', 'ミッションを作成・編集して朝のタスクを共有しましょう')
  // const { user } = useAuth() // Removed to avoid ReferenceError
  const [missions, setMissions] = useState<any[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [name, setName] = useState('')
  const [wakeTime, setWakeTime] = useState('07:00')
  const [addingStepFor, setAddingStepFor] = useState<string | null>(null)
  const [stepLabel, setStepLabel] = useState('')

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
    if (!name.trim()) {
      alert('ミッション名を入力してください')
      return
    }
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

  const addStep = (missionId: string) => {
    setAddingStepFor(missionId)
    setStepLabel('')
  }

  const handleStepTypeSelect = async (type: 'manual' | 'shake' | 'qr' | 'gps' | 'ai_detect', config: any) => {
    if (!addingStepFor || !stepLabel.trim()) {
      alert('ステップ名を入力してください')
      return
    }

    const currentSteps = await listMissionSteps(addingStepFor)
    const nextOrder = currentSteps.length > 0 ? Math.max(...currentSteps.map(s => s.order || 0)) + 1 : 1

    await createMissionStep(addingStepFor, {
      label: stepLabel,
      order: nextOrder,
      action_type: type,
      action_config: config
    })
    await loadSteps(addingStepFor)
    setAddingStepFor(null)
    setStepLabel('')
  }

  const removeStep = async (missionId: string, stepId: string) => {
    if (!confirm('ステップを削除しますか？')) return
    await deleteMissionStep(stepId)
    await loadSteps(missionId)
  }

  return (
    <div style={{ animation: 'float 6s ease-in-out infinite' }}>
      <style>{`
        @keyframes float {
          0% { transform: translateY(0px); }
          50% { transform: translateY(-10px); }
          100% { transform: translateY(0px); }
        }
      `}</style>
      <div style={{
        background: '#1c1c1e',
        borderRadius: 16,
        padding: 20,
        marginBottom: 16,
        boxShadow: '0 4px 12px rgba(0,0,0,0.2)'
      }}>
        <h3 style={{ margin: '0 0 16px 0', fontWeight: 700 }}>新しいミッション</h3>
        <label style={{ fontSize: 12, color: '#8e8e93' }}>ミッション名</label>
        <input
          style={{
            width: '100%',
            padding: 12,
            borderRadius: 12,
            border: '1px solid #333',
            background: '#2c2c2e',
            color: 'white',
            fontSize: 16,
            boxSizing: 'border-box',
            marginBottom: 12
          }}
          value={name}
          onChange={e => setName(e.target.value)}
          placeholder="例: 朝のルーティン"
        />
        <label style={{ fontSize: 12, color: '#8e8e93' }}>起床時間</label>
        <input
          style={{
            width: '100%',
            padding: 12,
            borderRadius: 12,
            border: '1px solid #333',
            background: '#2c2c2e',
            color: 'white',
            fontSize: 16,
            boxSizing: 'border-box',
            marginBottom: 12
          }}
          type="time"
          value={wakeTime}
          onChange={e => setWakeTime(e.target.value)}
        />
        <div style={{ marginTop: 12, textAlign: 'right' }}>
          <button
            style={{
              background: 'linear-gradient(135deg, #0a84ff, #5e5ce6)',
              color: 'white',
              border: 'none',
              padding: '12px 20px',
              borderRadius: 12,
              fontWeight: 600,
              fontSize: 16,
              cursor: 'pointer',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8
            }}
            onClick={add}
          >
            作成する
          </button>
        </div>
      </div>

      <h3 style={{ marginLeft: 8, marginBottom: 12, fontWeight: 700 }}>マイミッション</h3>
      {loading ? (
        <div style={{ background: '#1c1c1e', borderRadius: 16, padding: 20, marginBottom: 16, boxShadow: '0 4px 12px rgba(0,0,0,0.2)' }}><Skeleton lines={3} /></div>
      ) : missions.length === 0 ? (
        <div style={{ background: '#1c1c1e', borderRadius: 16, padding: 20, marginBottom: 16, boxShadow: '0 4px 12px rgba(0,0,0,0.2)', textAlign: 'center', color: '#666' }}>
          ミッションがありません。<br />新しいミッションを作成しましょう。
        </div>
      ) : (
        missions.map(m => (
          <div key={m.id} style={{ background: '#1c1c1e', borderRadius: 16, padding: 20, marginBottom: 16, boxShadow: '0 4px 12px rgba(0,0,0,0.2)', position: 'relative' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
              <div>
                <div style={{ fontSize: 18, fontWeight: 'bold' }}>{m.name}</div>
                <div style={{ fontSize: 12, color: '#8e8e93', display: 'flex', alignItems: 'center', gap: 4 }}><IconAlarm size={14} /> {m.wake_time} 起床</div>
              </div>
              <button
                style={{
                  background: '#ff453a',
                  color: 'white',
                  border: 'none',
                  padding: '6px 12px',
                  borderRadius: 12,
                  fontWeight: 600,
                  fontSize: 12,
                  cursor: 'pointer',
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 8
                }}
                onClick={() => remove(m.id)}
              >
                削除
              </button>
            </div>

            <div style={{ background: '#2c2c2e', borderRadius: 8, padding: 12 }}>
              <div style={{ marginBottom: 8, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: 12, color: '#8e8e93' }}>ステップ一覧</span>
                <button
                  style={{
                    background: '#3a3a3c',
                    color: 'white',
                    border: 'none',
                    padding: '4px 8px',
                    borderRadius: 12,
                    fontWeight: 600,
                    fontSize: 12,
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: 8
                  }}
                  onClick={() => addStep(m.id)}
                >
                  + 追加
                </button>
              </div>
              {(m.steps || []).length === 0 && <div style={{ fontSize: 12, color: '#8e8e93', textAlign: 'center' }}>ステップがありません</div>}
              {(m.steps || []).map((s: any) => (
                <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: '1px solid #3a3a3c' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{ width: 20, height: 20, borderRadius: '50%', background: '#0a84ff', color: 'white', fontSize: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{s.order}</div>
                    <div>
                      <div>{s.label}</div>
                      <div style={{ fontSize: 10, color: '#8e8e93', display: 'flex', alignItems: 'center', gap: 4 }}>
                        {s.action_type === 'shake' && <><IconShake size={12} /> シェイク ({s.action_config?.count}回)</>}
                        {s.action_type === 'qr' && <><IconQRCode size={12} /> QRスキャン</>}
                        {s.action_type === 'ai_detect' && <><IconScan size={12} /> AI検出 ({s.action_config?.targetLabel})</>}
                        {s.action_type === 'gps' && <><IconMapPin size={12} /> GPS移動 ({s.action_config?.distance}m)</>}
                        {s.action_type === 'manual' && <><IconTouch size={12} /> 手動</>}
                      </div>
                    </div>
                  </div>
                  <button style={{ background: 'none', border: 'none', color: '#ff453a', cursor: 'pointer', fontSize: 12 }} onClick={() => removeStep(m.id, s.id)}>削除</button>
                </div>
              ))}
            </div>
          </div>
        ))
      )}

      {/* Step Type Selector Modal */}
      <Modal
        open={addingStepFor !== null}
        onClose={() => setAddingStepFor(null)}
        title="新しいステップを追加"
      >
        <div style={{ padding: 16 }}>
          <label style={{ display: 'block', fontSize: 14, marginBottom: 4, fontWeight: 600 }}>
            ステップ名
          </label>
          <input
            style={{
              width: '100%',
              padding: 12,
              borderRadius: 12,
              border: '1px solid #333',
              background: '#2c2c2e',
              color: 'white',
              fontSize: 16,
              boxSizing: 'border-box',
              marginBottom: 20
            }}
            value={stepLabel}
            onChange={e => setStepLabel(e.target.value)}
            placeholder="例: ベッドから出る"
            autoFocus
          />
        </div>
        <StepTypeSelector
          onSelect={handleStepTypeSelect}
          onCancel={() => setAddingStepFor(null)}
        />
      </Modal>
    </div>
  )
}
