import React, { useEffect, useRef } from 'react'

export default function NameModal({ open, initial, onSave, onClose }:{open:boolean; initial?:string; onSave:(name:string)=>void; onClose:()=>void}){
  const ref = useRef<HTMLInputElement|null>(null)

  useEffect(()=>{
    if(open){
      setTimeout(()=> ref.current?.focus(), 50)
    }
  },[open])

  if(!open) return null

  return (
    <div role="dialog" aria-modal="true" style={{position:'fixed',left:0,top:0,right:0,bottom:0,display:'flex',alignItems:'center',justifyContent:'center',background:'rgba(10,10,12,0.36)'}} onClick={onClose}>
      <div style={{width:340,background:'white',borderRadius:12,padding:18,boxShadow:'0 16px 40px rgba(2,6,23,0.16)'}} onClick={e=>e.stopPropagation()}>
        <div style={{fontWeight:700,fontSize:16,marginBottom:8}}>表示名を変更</div>
        <input ref={ref} defaultValue={initial||''} aria-label="表示名" style={{width:'100%',padding:10,borderRadius:8,border:'1px solid #e6e9ef'}} onKeyDown={(e)=>{ if(e.key==='Enter'){ const v=(e.target as HTMLInputElement).value; onSave(v) } }} />
        <div style={{display:'flex',justifyContent:'flex-end',gap:8,marginTop:12}}>
          <button className="button" onClick={onClose} style={{padding:'8px 10px',borderRadius:8}}>キャンセル</button>
          <button className="button primary" onClick={()=>{ const v = ref.current?.value || ''; onSave(v) }} style={{padding:'8px 10px',borderRadius:8}}>保存</button>
        </div>
      </div>
    </div>
  )
}
