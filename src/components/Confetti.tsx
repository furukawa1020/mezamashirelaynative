import React, { useEffect, useState } from 'react'

type ConfettiProps = { trigger:boolean }

export default function Confetti({ trigger }: ConfettiProps){
  const [particles, setParticles] = useState<number[]>([])

  useEffect(()=>{
    if(!trigger) return
    // create 18 particles
    setParticles(Array.from({length:18}).map((_,i)=>i))
    const t = setTimeout(()=> setParticles([]), 900)
    return ()=> clearTimeout(t)
  },[trigger])

  if(particles.length===0) return null

  return (
    <div style={{position:'absolute',inset:0,pointerEvents:'none'}} aria-hidden>
      {particles.map(i=>{
        const left = 20 + Math.random()*60
        const color = ['#ff5a5f','#ffb400','#4cd964','#007aff','#5856d6'][i%5]
        const size = 6 + Math.random()*10
        const delay = Math.random()*200
        const style:React.CSSProperties = { position:'absolute', left:`${left}%`, top:'40%', width:size, height:size, background:color, borderRadius:4, transform:`translateY(0) scale(1)`, animation:`confetti-fall 900ms ${delay}ms cubic-bezier(.2,.8,.2,1) forwards` }
        return <span key={i} style={style} />
      })}
      <style>{`@keyframes confetti-fall{ to{ transform:translateY(240px) rotate(360deg) scale(0.7); opacity:0 } }`}</style>
    </div>
  )
}
