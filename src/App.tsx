import React, { useEffect, useState } from 'react'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import { useAuth } from './services/auth'
import { useLocalAuth } from './services/localAuth'
import { BLEProvider } from './services/BLEProvider'
import { AlarmProvider } from './services/AlarmProvider'
import Header from './components/Header'
import OnboardingModal from './components/OnboardingModal'

export default function App(){
  const auth = useAuth?.()
  const local = useLocalAuth?.()
  const user = auth?.user || local?.user
  const loading = auth?.loading ?? local?.loading ?? false

  const [showOnboard, setShowOnboard] = useState(false)

  useEffect(()=>{
    // show onboarding only for local users on first run
    try{
      const seen = localStorage.getItem('mz_seen_onboarding')
      if(local?.isLocal && !seen){ setShowOnboard(true) }
    }catch(e){}
  },[local?.isLocal])

  if(loading) return <div style={{display:'flex',height:'100vh',alignItems:'center',justifyContent:'center'}}><div className="small muted">読み込み中…</div></div>
  if(!user) return <Login />
  return (
    <AlarmProvider>
      <BLEProvider>
        <div>
          <div className="container">
            <Header />
            <Dashboard />
          </div>
          <OnboardingModal open={showOnboard} onClose={()=>{ try{ localStorage.setItem('mz_seen_onboarding','1') }catch(e){}; setShowOnboard(false) }} />
        </div>
      </BLEProvider>
    </AlarmProvider>
  )
}
