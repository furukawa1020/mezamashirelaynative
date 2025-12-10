import React from 'react'

export default function ShareModal({ open, data, onClose }:{open:boolean; data?:string; onClose:()=>void}){
  if(!open) return null
  const encoded = encodeURIComponent(data || '')
  const qrUrl = `https://chart.googleapis.com/chart?chs=300x300&cht=qr&chl=${encoded}`

  return (
    <div role="dialog" aria-modal="true" style={{position:'fixed',left:0,top:0,right:0,bottom:0,display:'flex',alignItems:'center',justifyContent:'center',background:'rgba(0,0,0,0.36)'}} onClick={onClose}>
      <div style={{width:420,background:'white',borderRadius:12,padding:16}} onClick={e=>e.stopPropagation()}>
        <h4>QRで共有</h4>
        <p className="small muted">スマホで読み取って、データを取り込めます（データ量が大きい場合は分割して使用してください）。</p>
        <div style={{display:'flex',gap:12,alignItems:'center'}}>
          <img src={qrUrl} alt="qr" style={{width:200,height:200,background:'#fff'}} />
          <div style={{flex:1}}>
            <textarea readOnly value={data} style={{width:'100%',height:180}} />
            <div style={{display:'flex',gap:8,justifyContent:'flex-end',marginTop:8}}>
              <button className="button" onClick={()=>{ navigator.clipboard.writeText(data||''); alert('コピーしました') }}>コピー</button>
              <button className="button" onClick={onClose}>閉じる</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
