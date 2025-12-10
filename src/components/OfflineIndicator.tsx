import React, { useEffect, useState } from 'react'

export default function OfflineIndicator(){
  const [online, setOnline] = useState<boolean>(typeof navigator !== 'undefined' ? navigator.onLine : true)

  useEffect(()=>{
    function onOnline(){ setOnline(true) }
    function onOffline(){ setOnline(false) }
    window.addEventListener('online', onOnline)
    window.addEventListener('offline', onOffline)
    return ()=>{
      window.removeEventListener('online', onOnline)
      window.removeEventListener('offline', onOffline)
    }
  },[])

  return (
    <div className={online ? 'online-badge small' : 'offline-badge small'} aria-live="polite" aria-atomic="true">
      {online ? 'オンライン' : 'オフライン'}
    </div>
  )
}
