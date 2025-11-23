import React, { useState } from 'react'
import usePageMeta from '../hooks/usePageMeta'
import { useAuth } from '../services/auth'

export default function Login() {
  usePageMeta('ようこそ', 'めざましリレーを始めましょう')
  const { login } = useAuth()

  return (
    <div className="container" style={{ height: '100vh', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
      <h1>めざましリレー</h1>
      <p style={{ marginBottom: 24 }}>みんなでひとりで起きる</p>
      <button className="button" onClick={() => login()}>はじめる</button>
    </div>
  )
}
