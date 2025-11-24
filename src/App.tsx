import React, { useEffect, useState } from 'react'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import { useAuth } from './services/auth'
import { BLEProvider } from './services/BLEProvider'
import { AlarmProvider } from './services/AlarmProvider'
import Header from './components/Header'
import OnboardingModal from './components/OnboardingModal'

export default function App() {
  const { user, loading } = useAuth()
  const [showOnboard, setShowOnboard] = useState(false)

  useEffect(() => {
    // show onboarding only for local users on first run
    try {
      const seen = localStorage.getItem('mz_seen_onboarding')
      if (user && !seen) { setShowOnboard(true) }
    } catch (e) { }
  }, [user])

  if (loading) return (
    <div style={{
      display: 'flex',
      height: '100vh',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#121214',
      color: '#ffffff'
    }}>
      <div style={{ fontSize: 12, color: '#8e8e93' }}>読み込み中…</div>
    </div>
  )
  if (!user) return <Login />

  return (
    <AlarmProvider>
      <BLEProvider>
        <div style={{ background: '#121214', minHeight: '100vh', color: '#ffffff' }}>
          <div style={{
            maxWidth: 600,
            margin: '0 auto',
            padding: 20,
            boxSizing: 'border-box',
            minHeight: '100vh'
          }}>
            <Header />
            <Dashboard />
          </div>
          <OnboardingModal open={showOnboard} onClose={() => { try { localStorage.setItem('mz_seen_onboarding', '1') } catch (e) { }; setShowOnboard(false) }} />
        </div>
      </BLEProvider>
    </AlarmProvider>
  )
}
