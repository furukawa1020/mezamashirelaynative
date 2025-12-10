import React, { useEffect, useState, useRef } from 'react'
import Confetti from './Confetti'
import { useSound, playSuccess } from '../services/soundProvider'

export default function StepItem({step, onComplete}:{step:any; onComplete:(id:string)=>void}){
  const [done,setDone] = useState(step.result === 'success')
  const [showConfetti,setShowConfetti] = useState(false)
  const prevRef = useRef(step.result)
  const { muted } = useSound()

  useEffect(()=>{
    const nowDone = step.result === 'success'
    // trigger confetti only when transitioning from not-done to done
    if(!prevRef.current || prevRef.current !== 'success'){
      if(nowDone && !done){
        setShowConfetti(true)
  // sound feedback if enabled
  try{ if(!muted) playSuccess() }catch(e){}
        // haptic feedback on supported devices
        try{ if('vibrate' in navigator) (navigator as any).vibrate([30,20,30]) }catch(e){}
        // hide confetti after a short delay
        setTimeout(()=> setShowConfetti(false), 900)
      }
    }
    prevRef.current = step.result
    setDone(nowDone)
  },[step.result])

  // 所要時間を計算（完了している場合）
  const lapTime = done && step.finished_at && step.started_at 
    ? Math.floor((step.finished_at - step.started_at) / 1000)
    : null;

  return (
    <div style={{position:'relative'}}>
      <div className={`step-item ${done? 'done':''}`} style={{
        transition: 'all 0.3s ease',
        transform: done ? 'scale(0.98)' : 'scale(1)',
      }}>
        <div style={{display:'flex',gap:12,alignItems:'center',flex:1}}>
          <div style={{
            width:40,
            height:40,
            display:'flex',
            alignItems:'center',
            justifyContent:'center',
            borderRadius:8,
            background: done ? 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' : '#fbfcff',
            boxShadow: done ? '0 4px 12px rgba(102,126,234,0.4)' : 'inset 0 1px 0 rgba(255,255,255,0.6)',
            transition: 'all 0.3s ease',
          }}>
            <div className="checkmark" aria-hidden>{done ? (
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M20 6L9 17l-5-5" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
            ) : (
              <div style={{width:12,height:12,border:'2px solid #ccc',borderRadius:'50%'}} />
            )}</div>
          </div>
          <div style={{flex:1}}>
            <div style={{fontWeight:600,fontSize:15}}>{step.label}</div>
            <div style={{display:'flex',gap:8,alignItems:'center',marginTop:4}}>
              <div className="sub small">{step.type || 'manual'}</div>
              {done && lapTime !== null && (
                <div style={{
                  fontSize:12,
                  fontWeight:600,
                  color:'#667eea',
                  background:'rgba(102,126,234,0.1)',
                  padding:'2px 8px',
                  borderRadius:4,
                }}>
                  ⏱️ {lapTime}秒
                </div>
              )}
              {step.ble_event && (
                <div style={{
                  fontSize:11,
                  color:'#666',
                  background:'#f0f0f0',
                  padding:'2px 6px',
                  borderRadius:3,
                }}>
                  {step.ble_event}
                </div>
              )}
            </div>
          </div>
        </div>

        <div>
          {done ? (
            <span style={{
              color:'#22c55e',
              fontWeight:700,
              fontSize:16,
            }}>✓ 完了</span>
          ) : (
            <button className="button" onClick={()=>onComplete(step.id)}>完了にする</button>
          )}
        </div>
      </div>
      <Confetti trigger={showConfetti} />
    </div>
  )
}
