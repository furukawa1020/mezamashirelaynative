import React, { createContext, useContext, useState, useCallback, useEffect } from 'react'

type Toast = { id:number; text:string }
type ToastContext = { showToast:(text:string)=>void }

const ToastCtx = createContext<ToastContext>({ showToast:()=>{} })

export function ToastProvider({ children }:{children:React.ReactNode}){
  const [list, setList] = useState<Toast[]>([])
  const showToast = useCallback((text:string)=>{
    const id = Date.now()
    setList(s=>[...s, {id,text}])
    setTimeout(()=> setList(s=>s.filter(t=>t.id!==id)), 2600)
  },[])

  return (
    <ToastCtx.Provider value={{ showToast }}>
      {children}
      <div aria-live="polite" style={{position:'fixed',left:0,right:0,bottom:28,display:'flex',justifyContent:'center',pointerEvents:'none'}}>
        <div style={{display:'flex',flexDirection:'column',gap:8,alignItems:'center'}}>
          {list.map(t=> (
            <div key={t.id} style={{pointerEvents:'auto',background:'rgba(15,15,20,0.96)',color:'white',padding:'8px 14px',borderRadius:12,boxShadow:'0 8px 20px rgba(0,0,0,0.14)',transform:'translateY(0)',opacity:1,transition:'all .28s ease'}}>{t.text}</div>
          ))}
        </div>
      </div>
    </ToastCtx.Provider>
  )
}

export function useToast(){
  return useContext(ToastCtx)
}

export default ToastProvider
