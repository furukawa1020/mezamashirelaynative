import React from 'react'
import IconButton from './IconButton'
import { useSound } from '../services/soundProvider'

interface HeaderWithSoundProps {
  user: any;
  signOut: () => void;
}

export default function HeaderWithSound({ user, signOut }: HeaderWithSoundProps) {
  // const { user, signOut } = useAuth() // Removed to avoid ReferenceError
  const { muted, setMuted } = useSound()

  return (
    <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, marginBottom: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ width: 44, height: 44, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 10, background: 'linear-gradient(180deg,#fff,#f1f6ff)', boxShadow: '0 6px 18px rgba(10,10,10,0.06)' }}>
          <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 2v6" stroke="#007aff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
            <circle cx="12" cy="14" r="6" stroke="#0b1220" strokeWidth="1.2" fill="#ffffff" />
          </svg>
        </div>
        <div>
          <div style={{ fontWeight: 700, fontSize: 18 }}>めざましリレー</div>
          <div className="sub">みんなでひとりで起きる</div>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div className="small muted">{user?.displayName || user?.email}</div>
        <IconButton ariaLabel={muted ? '音をオン' : '音をオフ'} onClick={() => setMuted(!muted)}>
          {muted ? (
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M16 7L7 16" stroke="#666" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M7 9v6h4l5 4V5l-5 4H7z" stroke="#666" strokeWidth="1.2" fill="none" />
            </svg>
          ) : (
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M7 9v6h4l5 4V5l-5 4H7z" stroke="#0b1220" strokeWidth="1.2" fill="none" />
              <path d="M16 8a4 4 0 010 8" stroke="#0b1220" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          )}
        </IconButton>
        <button className="button" style={{ padding: '8px 10px', borderRadius: 10 }} onClick={signOut}>サインアウト</button>
      </div>
    </header>
  )
}
