import React, { useEffect, useState } from 'react'
import usePageMeta from '../hooks/usePageMeta'
import { useAuth } from '../services/AuthContext'
import { listTodaySessionsByUser, listSessionSteps, completeSessionStep } from '../services/localStore'
import { playSuccess } from '../services/soundProvider'
import { useSound } from '../services/soundProvider'
import { useToast } from '../components/Toast'

export default function Sessions() {
  usePageMeta('セッション', '今日のセッションとステップを確認・操作します')
  const { user } = useAuth()
  const [sessions, setSessions] = useState<any[]>([])
  const [stepsMap, setStepsMap] = useState<Record<string, any[]>>({})

  useEffect(() => {
    if (!user) return
    listTodaySessionsByUser(user.uid).then(s => {
      setSessions(s)
      s.forEach(async (sess: any) => {
        const st = await listSessionSteps(sess.id)
        setStepsMap(prev => ({ ...prev, [sess.id]: st }))
      })
    }).catch(() => { })
  }, [user])

  const { muted } = useSound()
  const { showToast } = useToast()

  const onComplete = async (sessionId: string, stepId: string) => {
    await completeSessionStep(stepId)
    const st = await listSessionSteps(sessionId)
    setStepsMap(prev => ({ ...prev, [sessionId]: st }))
    // refresh sessions to reflect possible session completion / rank updates
    const s = await listTodaySessionsByUser(user!.uid)
    setSessions(s)
    if (!muted) playSuccess()
    // show toast feedback
    try { showToast && showToast('ステップを完了しました') } catch (e) { }
  }

  return (
    <div className="container">
      <h2>今日のセッション</h2>
      {sessions.length === 0 && <div className="card">今日のセッションはありません</div>}
      {sessions.map(s => (
        <div className="card" key={s.id}>
          <h3>セッション: {s.id}</h3>
          <div>ミッション: {s.mission_id}</div>
          <div>状態: {s.status}</div>
          <div style={{ marginTop: 8 }}>
            <h4>ステップ</h4>
            {(stepsMap[s.id] || []).map(step => (
              <div key={step.id} style={{ padding: 6, borderBottom: '1px solid #eee' }}>
                <div><strong>{step.label}</strong> <span style={{ fontSize: 12, color: '#666' }}>({step.type || 'manual'})</span></div>
                <div style={{ marginTop: 6 }}>
                  {step.result === 'success' ? <span style={{ color: 'green' }}>完了</span> : <button className="button" onClick={() => onComplete(s.id, step.id)}>完了にする</button>}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}
