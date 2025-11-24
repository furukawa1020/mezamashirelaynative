import React, { useState } from 'react'
import { useAuth } from '../services/auth'
import { seedSampleData } from '../services/localStore'

interface OnboardingModalProps {
  open: boolean
  onClose: () => void
}

export default function OnboardingModal({ open, onClose }: OnboardingModalProps) {
  const { user } = useAuth()
  const [currentStep, setCurrentStep] = useState(0)
  const [loading, setLoading] = useState(false)

  if (!open) return null

  const steps = [
    {
      title: '🌅 めざましリレーへようこそ！',
      content: (
        <div>
          <p style={{ color: '#374151', lineHeight: 1.6 }}>
            めざましリレーは、朝のタスクを楽しくこなすためのアプリです。
          </p>
          <ul style={{ color: '#374151', lineHeight: 1.8 }}>
            <li><strong>📱 センサーを活用</strong>: スマホを振る、カメラで物を検出、位置情報など</li>
            <li><strong>🎯 ミッション作成</strong>: 自分だけの朝のルーティンを設定</li>
            <li><strong>👥 グループ機能</strong>: 友達と一緒に起きる（オプション）</li>
          </ul>
        </div>
      )
    },
    {
      title: '🎮 使える機能',
      content: (
        <div>
          <div style={{ display: 'grid', gap: 12 }}>
            <div style={{ padding: 12, background: '#f3f4f6', borderRadius: 8 }}>
              <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>👋 シェイク</div>
              <div style={{ fontSize: 14, color: '#6b7280' }}>スマホを振って目を覚ます</div>
            </div>
            <div style={{ padding: 12, background: '#f3f4f6', borderRadius: 8 }}>
              <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>🤖 AI物体検出</div>
              <div style={{ fontSize: 14, color: '#6b7280' }}>カメラでコーヒーカップなどを探す</div>
            </div>
            <div style={{ padding: 12, background: '#f3f4f6', borderRadius: 8 }}>
              <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>📍 GPS移動</div>
              <div style={{ fontSize: 14, color: '#6b7280' }}>指定した距離を歩く</div>
            </div>
            <div style={{ padding: 12, background: '#f3f4f6', borderRadius: 8 }}>
              <div style={{ fontSize: 16, fontWeight: 600, marginBottom: 4 }}>📷 QRコード</div>
              <div style={{ fontSize: 14, color: '#6b7280' }}>特定の場所のQRをスキャン</div>
            </div>
          </div>
        </div>
      )
    },
    {
      title: '🚀 サンプルミッションを作成',
      content: (
        <div>
          <p style={{ color: '#374151', lineHeight: 1.6 }}>
            すぐに試せるように、サンプルミッションを自動作成します。
          </p>
          <div style={{ padding: 16, background: '#dbeafe', borderRadius: 8, marginTop: 12 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: '#1e40af', marginBottom: 8 }}>
              📋 サンプルミッション「朝のルーティン」
            </div>
            <ul style={{ margin: 0, paddingLeft: 20, color: '#1e3a8a', fontSize: 14 }}>
              <li>ベッドから出る（シェイク）</li>
              <li>コーヒーカップを見つける（AI）</li>
              <li>少し歩く（GPS）</li>
              <li>完了！（手動）</li>
            </ul>
          </div>
          <p style={{ color: '#6b7280', fontSize: 13, marginTop: 12 }}>
            ※ 後で「ミッション」タブから編集・削除できます
          </p>
        </div>
      )
    }
  ]

  const handleNext = async () => {
    if (currentStep < steps.length - 1) {
      setCurrentStep(currentStep + 1)
    } else {
      // Last step - create sample mission and close
      setLoading(true)
      try {
        if (user) {
          await seedSampleData(user.uid)
        }
        localStorage.setItem('mz_seen_onboarding', '1')
        onClose()
      } catch (e) {
        console.error('Failed to create sample mission:', e)
        localStorage.setItem('mz_seen_onboarding', '1')
        onClose()
      } finally {
        setLoading(false)
      }
    }
  }

  const handleSkip = () => {
    localStorage.setItem('mz_seen_onboarding', '1')
    onClose()
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      style={{
        position: 'fixed',
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'rgba(10,10,12,0.5)',
        zIndex: 1000
      }}
      onClick={handleSkip}
    >
      <div
        style={{
          width: '90%',
          maxWidth: 500,
          background: 'white',
          borderRadius: 16,
          padding: 24,
          boxShadow: '0 24px 60px rgba(2,6,23,0.18)',
          maxHeight: '80vh',
          overflow: 'auto'
        }}
        onClick={e => e.stopPropagation()}
      >
        <h2 style={{ margin: 0, marginBottom: 16, fontSize: 20 }}>
          {steps[currentStep].title}
        </h2>

        {steps[currentStep].content}

        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginTop: 24,
          paddingTop: 16,
          borderTop: '1px solid #e5e7eb'
        }}>
          <div style={{ fontSize: 13, color: '#9ca3af' }}>
            {currentStep + 1} / {steps.length}
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button
              className="button"
              onClick={handleSkip}
              style={{
                padding: '8px 16px',
                background: '#f3f4f6',
                color: '#374151'
              }}
            >
              スキップ
            </button>
            <button
              className="button"
              onClick={handleNext}
              disabled={loading}
              style={{
                padding: '8px 16px',
                background: loading ? '#9ca3af' : '#0a84ff'
              }}
            >
              {loading ? '作成中...' : currentStep === steps.length - 1 ? '始める！' : '次へ'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
