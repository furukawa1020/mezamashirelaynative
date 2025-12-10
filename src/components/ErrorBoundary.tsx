/**
 * ErrorBoundary - React エラーをキャッチして表示
 */

import React from 'react';

interface Props {
  children: React.ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('[ErrorBoundary] Caught error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          padding: 24,
          maxWidth: 600,
          margin: '40px auto',
          background: '#fff3cd',
          border: '1px solid #ffc107',
          borderRadius: 8,
        }}>
          <h2 style={{ color: '#856404', marginBottom: 16 }}>
            ⚠️ エラーが発生しました
          </h2>
          <p style={{ marginBottom: 12, color: '#856404' }}>
            ページの読み込み中に問題が発生しました。
          </p>
          <details style={{ marginBottom: 16 }}>
            <summary style={{ cursor: 'pointer', color: '#856404' }}>
              エラー詳細
            </summary>
            <pre style={{
              background: '#fff',
              padding: 12,
              borderRadius: 4,
              overflow: 'auto',
              fontSize: 13,
              marginTop: 8,
            }}>
              {this.state.error?.toString()}
              {'\n\n'}
              {this.state.error?.stack}
            </pre>
          </details>
          <button
            onClick={() => {
              // Service Worker とキャッシュをクリア
              if ('serviceWorker' in navigator) {
                navigator.serviceWorker.getRegistrations().then(regs => {
                  regs.forEach(reg => reg.unregister());
                });
              }
              if ('caches' in window) {
                caches.keys().then(keys => {
                  keys.forEach(key => caches.delete(key));
                });
              }
              // リロード
              window.location.reload();
            }}
            style={{
              padding: '12px 24px',
              background: '#ffc107',
              color: '#000',
              border: 'none',
              borderRadius: 8,
              cursor: 'pointer',
              fontWeight: 600,
            }}
          >
            キャッシュをクリアして再読み込み
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
