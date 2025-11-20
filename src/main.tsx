import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import './styles.css'
import { AuthProvider } from './services/auth'
import LocalAuthProvider from './services/localAuth'
import { SoundProvider } from './services/soundProvider'
import ToastProvider from './components/Toast'
import { ErrorBoundary } from './components/ErrorBoundary'

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ErrorBoundary>
      {(import.meta.env.VITE_USE_FIREBASE === '1') ? (
        // Explicit opt-in to Firebase when VITE_USE_FIREBASE=1
        <AuthProvider>
          <SoundProvider>
            <ToastProvider>
              <App />
            </ToastProvider>
          </SoundProvider>
        </AuthProvider>
      ) : (
        // Default: local-first mode
        <LocalAuthProvider>
          <SoundProvider>
            <ToastProvider>
              <App />
            </ToastProvider>
          </SoundProvider>
        </LocalAuthProvider>
      )}
    </ErrorBoundary>
  </React.StrictMode>
)

// register service worker for PWA
// 一時的に無効化（デバッグ用）
/*
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/src/sw.js')
      .then(reg => {
        console.log('[SW] Registered:', reg.scope)
        // 新しいSWが待機中なら即座にアクティブ化
        if (reg.waiting) {
          reg.waiting.postMessage({ type: 'SKIP_WAITING' })
        }
      })
      .catch(err => {
        console.error('[SW] Registration failed:', err)
      })
  })
  
  // SW更新時に自動リロード
  let refreshing = false
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!refreshing) {
      refreshing = true
      window.location.reload()
    }
  })
}
*/
