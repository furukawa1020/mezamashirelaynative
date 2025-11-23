import React, { useState } from 'react'
import { useAuth } from '../services/auth'
import IconButton from './IconButton'
import { useSound } from '../services/soundProvider'
import NameModal from './NameModal'
import { useToast } from './Toast'
import OfflineIndicator from './OfflineIndicator'
import InstallPrompt from './InstallPrompt'

// Accessible header with sound toggle
export default function Header() {
  const { user, signOut, updateProfile } = useAuth()
  const { muted, setMuted } = useSound()
  const { showToast } = useToast()

  const [openName, setOpenName] = useState(false)

  return (
    <>
      <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, marginBottom: 18 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ width: 44, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 10, background: 'linear-gradient(180deg,#fff,#f1f6ff)', boxShadow: '0 6px 18px rgba(10,10,10,0.06)' }}>
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
              <path d="M12 2v6" stroke="#007aff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
              <circle cx="12" cy="14" r="6" stroke="#0b1220" strokeWidth="1.2" fill="#ffffff" />
            </svg>
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ fontWeight: 700, fontSize: 18 }}>めざましリレー</div>
              <OfflineIndicator />
            </div>
            <div className="sub">みんなでひとりで起きる</div>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div className="small muted" aria-live="polite">{user?.displayName || user?.email}</div>
          <IconButton ariaLabel={muted ? '音をオン' : '音をオフ'} onClick={() => setMuted(!muted)} role="switch" ariaChecked={!muted}>
            {muted ? (
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
                <path d="M16 7L7 16" stroke="#666" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
                <path d="M7 9v6h4l5 4V5l-5 4H7z" stroke="#666" strokeWidth="1.2" fill="none" />
              </svg>
            ) : (
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
                <path d="M7 9v6h4l5 4V5l-5 4H7z" stroke="#0b1220" strokeWidth="1.2" fill="none" />
                <path d="M16 8a4 4 0 010 8" stroke="#0b1220" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            )}
          </IconButton>

          <button className="button" style={{ padding: '8px 10px', borderRadius: 10 }} onClick={() => setOpenName(true)} aria-label="表示名を編集">名前編集</button>
          <NameModal open={openName} initial={user?.displayName || ''} onClose={() => setOpenName(false)} onSave={async (name) => {
            try {
              await updateProfile(name)
              showToast('表示名を保存しました')
            } catch (e) { }
            setOpenName(false)
          }} />

          <button className="button" style={{ padding: '8px 10px', borderRadius: 10 }} onClick={signOut}>サインアウト</button>
        </div>
      </header>
      {/* show install prompt at app-level */}
      <InstallPrompt />
    </>
  )
}
