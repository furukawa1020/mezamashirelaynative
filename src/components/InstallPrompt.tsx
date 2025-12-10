import React, { useEffect, useState } from 'react'

export default function InstallPrompt(){
  const [deferred, setDeferred] = useState<any>(null)
  const [visible, setVisible] = useState(false)

  useEffect(()=>{
    function onBefore(e:any){
      e.preventDefault()
      setDeferred(e)
      setVisible(true)
    }
    window.addEventListener('beforeinstallprompt', onBefore as any)
    return ()=> window.removeEventListener('beforeinstallprompt', onBefore as any)
  },[])

  const onInstall = async ()=>{
    if(!deferred) return
    try{
      deferred.prompt()
      const choice = await deferred.userChoice
      setVisible(false)
      setDeferred(null)
    }catch(e){ setVisible(false); setDeferred(null) }
  }

  if(!visible) return null
  return (
    <div style={{position:'fixed',right:18,bottom:18,background:'#fff',padding:12,borderRadius:12,boxShadow:'0 8px 30px rgba(10,10,10,0.08)',zIndex:999}}>
      <div style={{fontWeight:700}}>アプリをホーム画面に追加</div>
      <div className="small muted" style={{marginTop:6}}>素早くアクセスできるようホームに追加できます</div>
      <div style={{marginTop:8,display:'flex',gap:8}}>
        <button className="button" onClick={onInstall}>追加</button>
        <button className="button" style={{background:'#f3f5f7',color:'#0b1220'}} onClick={()=>setVisible(false)}>閉じる</button>
      </div>
    </div>
  )
}
