import React, { useEffect, useState, useRef } from 'react'
import * as local from '../services/localStore'
import { useToast } from './Toast'

export default function AutoBackup(){
  const [enabled, setEnabled] = useState(false)
  const [intervalMin, setIntervalMin] = useState(15)
  const timerRef = useRef<number|undefined>(undefined)
  const { showToast } = useToast()

  useEffect(()=>{
    if(enabled){
      // perform initial backup
      local.saveBackup()
      showToast('バックアップを開始しました')
      timerRef.current = window.setInterval(()=>{ local.saveBackup(); showToast('自動バックアップを保存しました') }, intervalMin * 60 * 1000)
    }else{
      if(timerRef.current) clearInterval(timerRef.current)
      timerRef.current = undefined
    }
    return ()=>{ if(timerRef.current) clearInterval(timerRef.current) }
  },[enabled, intervalMin])

  const onManual = ()=>{
    const ok = local.saveBackup()
    showToast(ok ? 'バックアップ保存しました' : 'バックアップに失敗しました')
  }

  const latest = local.getLatestBackup()

  return (
    <div className="card" style={{marginTop:12}}>
      <h4>自動バックアップ</h4>
      <div style={{display:'flex',gap:8,alignItems:'center',flexWrap:'wrap'}}>
        <label style={{display:'flex',alignItems:'center',gap:8}}>
          <input type="checkbox" checked={enabled} onChange={e=>setEnabled(e.target.checked)} /> 自動バックアップを有効にする
        </label>
        <label style={{display:'flex',alignItems:'center',gap:8}}>
          <span style={{marginRight:6}}>間隔（分）:</span>
          <input type="number" value={intervalMin} min={1} onChange={e=>setIntervalMin(Number(e.target.value))} style={{width:64}} />
        </label>
        <button className="button" onClick={onManual}>今すぐバックアップ</button>
      </div>
      <div style={{marginTop:8}}>
        <div className="small muted">最新バックアップ: {latest ? new Date(latest.created_at).toLocaleString() : 'なし'}</div>
      </div>
    </div>
  )
}
