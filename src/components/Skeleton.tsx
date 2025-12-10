import React from 'react'

export default function Skeleton({lines=3}:{lines?:number}){
  const items = Array.from({length:lines}).map((_,i)=> (
    <div key={i} className="skeleton-row" style={{marginBottom:10}}>
      <div className="skeleton-avatar" />
      <div style={{flex:1,marginLeft:12}}>
        <div className="skeleton-line short" />
        <div className="skeleton-line" style={{marginTop:8}} />
      </div>
    </div>
  ))
  return <div aria-hidden="true">{items}</div>
}
