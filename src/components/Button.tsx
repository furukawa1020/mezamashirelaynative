import React from 'react'
import { playClick } from '../services/soundProvider'
import { useSound } from '../services/soundProvider'

export default function Button({children, onClick, className, ariaLabel}:{children:React.ReactNode; onClick?:()=>void; className?:string; ariaLabel?:string}){
  const { muted } = useSound()
  const handle = (e:React.MouseEvent)=>{
    if(!muted) playClick()
    onClick && onClick()
  }
  return (
    <button aria-label={ariaLabel} className={`button ${className||''}`} onClick={handle}>
      {children}
    </button>
  )
}
