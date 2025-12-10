import React, { useEffect, useState } from 'react'
import { useAuth } from '../services/auth'
import { createMission, listMissions, createMissionStep, listMissionSteps } from '../services/firestore'
import usePageMeta from '../hooks/usePageMeta'
import Skeleton from '../components/Skeleton'

export default function Missions(){
  usePageMeta('ミッション一覧','ミッションを作成・編集して朝のタスクを共有しましょう')
  const { user } = useAuth()
  const [missions, setMissions] = useState<any[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [name, setName] = useState('')
  const [wakeTime, setWakeTime] = useState('07:00')

  useEffect(()=>{
    if(!user) return
    setLoading(true)
    listMissions(user.uid).then(setMissions).catch(()=>{}).finally(()=>setLoading(false))
  },[user])

  const loadSteps = async (missionId:string)=>{
    const s = await listMissionSteps(missionId)
    setMissions(prev=> prev.map(m=> m.id===missionId ? { ...m, steps: s } : m))
  }

  const add = async ()=>{
    if(!user) return
    await createMission(user.uid, { name, wake_time: wakeTime })
    setName('')
    const updated = await listMissions(user.uid)
    setMissions(updated)
  }

  const addStep = async (missionId:string)=>{
    const label = prompt('ステップ名を入力')
    if(!label) return
    // 既存のステップを取得して、次の order を決定
    const currentSteps = await listMissionSteps(missionId)
    const nextOrder = currentSteps.length > 0 ? Math.max(...currentSteps.map(s => s.order || 0)) + 1 : 1
    await createMissionStep(missionId, { label, order: nextOrder })
    await loadSteps(missionId)
  }

  return (
    <div className="container">
      <h2>ミッション</h2>
      <div className="card">
        <label>ミッション名</label>
        <input className="input" value={name} onChange={e=>setName(e.target.value)} />
        <label style={{marginTop:8}}>起床時間</label>
        <input className="input" type="time" value={wakeTime} onChange={e=>setWakeTime(e.target.value)} />
        <div style={{marginTop:8}}>
          <button className="button" onClick={add}>追加</button>
        </div>
      </div>

      <div className="card">
        <h3>あなたのミッション一覧</h3>
        {loading ? (
          <div style={{padding:8}}><Skeleton lines={4} /></div>
        ) : missions.length===0 ? (
          <div>まだミッションがありません</div>
        ) : (
          missions.map(m=> (
            <div key={m.id} style={{padding:8,borderBottom:'1px solid #eee'}}>
              <div style={{display:'flex',justifyContent:'space-between'}}>
                <strong>{m.name}</strong>
                <div><button className="button" onClick={()=>addStep(m.id)}>ステップ追加</button></div>
              </div>
              <div style={{fontSize:12,color:'#666'}}>起床時間: {m.wake_time}</div>
              <div style={{marginTop:8}}>
                {(m.steps || []).map((s:any)=> (
                  <div key={s.id} style={{padding:6,borderTop:'1px solid #f0f0f0'}}>{s.order}. {s.label} <span style={{fontSize:12,color:'#666'}}>({s.type})</span></div>
                ))}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
