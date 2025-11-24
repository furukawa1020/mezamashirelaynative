import React, { useState } from 'react'
import usePageMeta from '../hooks/usePageMeta'
import { useAuth } from '../services/auth'

export default function Login() {
  usePageMeta('ようこそ', 'めざましリレーを始めましょう')
  const { login } = useAuth()

  return (
    <div style={{
      maxWidth: 600,
      margin: '0 auto',
      padding: 20,
      boxSizing: 'border-box',
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center'
    }}>
      <h1 style={{ margin: '0 0 16px 0', fontWeight: 700 }}>めざましリレー</h1>
      <p style={{ marginBottom: 24, color: '#8e8e93' }}>みんなでひとりで起きる</p>
      <button
        style={{
          background: 'linear-gradient(135deg, #0a84ff, #5e5ce6)',
          color: 'white',
          border: 'none',
          padding: '12px 20px',
          borderRadius: 12,
          fontWeight: 600,
          fontSize: 16,
          cursor: 'pointer',
          display: 'inline-flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 8
        }}
        onClick={() => login()}
      >
        はじめる
      </button>
    </div>
  )
}
