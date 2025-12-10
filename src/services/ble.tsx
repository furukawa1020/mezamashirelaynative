// BLE / NFC のスタブとフック
import { useEffect } from 'react'

export function useBLEStub(onEvent: (ev:any)=>void){
  useEffect(()=>{
    const handler = (e:any)=> onEvent(e.detail)
    window.addEventListener('mezamashi:step', handler as EventListener)
    return ()=> window.removeEventListener('mezamashi:step', handler as EventListener)
  },[onEvent])
}

export async function requestDevice(){
  // 実装はブラウザ互換性に依存するため、サンプルでは未実装
  throw new Error('Web Bluetooth はこの環境ではサポートされていません（スタブ）')
}
