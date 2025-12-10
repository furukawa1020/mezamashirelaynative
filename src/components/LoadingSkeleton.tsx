import React from 'react'

export default function LoadingSkeleton({width='100%', height=16, style}:{width?:string|number; height?:number; style?:React.CSSProperties}){
  return (
    <div style={{width, height, borderRadius:8, background:'linear-gradient(90deg,#f3f4f8,#eef1fb,#f3f4f8)', backgroundSize:'200% 100%', animation:'skeleton 1.6s linear infinite', ...style}} />
  )
}
