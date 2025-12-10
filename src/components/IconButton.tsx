import React from 'react'

type Props = {
  children: React.ReactNode
  onClick?: ()=>void
  ariaLabel?: string
  role?: string
  ariaChecked?: boolean
}

export default function IconButton({children, onClick, ariaLabel, role, ariaChecked}:Props){
  return (
    <button
      className="icon-button"
      aria-label={ariaLabel}
      role={role}
      aria-checked={ariaChecked}
      onClick={onClick}
      onKeyDown={(e)=>{ if(e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onClick && onClick() } }}
      tabIndex={0}
      style={{background:'transparent',border:'none',padding:8,borderRadius:10,display:'inline-flex',alignItems:'center',justifyContent:'center'}}
    >
      {children}
    </button>
  )
}
