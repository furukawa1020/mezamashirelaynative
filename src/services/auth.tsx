import React, { createContext, useContext, useEffect, useState } from 'react'

export type User = {
  uid: string
  displayName: string | null
  email: string | null
  isAnonymous: boolean
}

interface AuthContextValue {
  user: User | null
  loading: boolean
  updateProfile: (name: string) => Promise<void>
  login: () => Promise<void>
  signOut: () => Promise<void>
  // Stub for compatibility, or we can remove it if we fix all call sites
  sendAccountClaimLink?: (email: string) => Promise<boolean>
}

const AuthContext = createContext<AuthContextValue | null>(null)

const STORAGE_KEY = 'mz_local_user'

function genId() {
  return 'local-' + Math.random().toString(36).slice(2, 9)
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) {
        const parsed = JSON.parse(raw)
        // Ensure compatibility with User type
        setUser({
          uid: parsed.id || parsed.uid,
          displayName: parsed.name || parsed.displayName || 'ゲスト',
          email: parsed.email || null,
          isAnonymous: true
        })
      } else {
        const newUser = { uid: genId(), displayName: 'ゲスト', email: null, isAnonymous: true }
        localStorage.setItem(STORAGE_KEY, JSON.stringify(newUser))
        setUser(newUser)
      }
    } catch (e) {
      const newUser = { uid: genId(), displayName: 'ゲスト', email: null, isAnonymous: true }
      setUser(newUser)
    }
    setLoading(false)
  }, [])

  const updateProfile = async (name: string) => {
    if (!user) return
    const newUser = { ...user, displayName: name }
    setUser(newUser)
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(newUser))
    } catch (e) { }
  }

  const login = async () => {
    const newUser = { uid: genId(), displayName: 'ゲスト', email: null, isAnonymous: true }
    setUser(newUser)
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(newUser))
    } catch (e) { }
  }

  const signOut = async () => {
    try {
      localStorage.removeItem(STORAGE_KEY)
    } catch (e) { }
    setUser(null)
    // Reload to reset state or redirect to login
    window.location.reload()
  }

  const value: AuthContextValue = {
    user,
    loading,
    updateProfile,
    login,
    signOut,
    sendAccountClaimLink: async () => false // Not supported in local mode
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    // Return a dummy context if used outside provider (shouldn't happen) or just null
    // But for safety let's throw or return default
    return { user: null, loading: false, updateProfile: async () => { }, signOut: async () => { } }
  }
  return context
}
