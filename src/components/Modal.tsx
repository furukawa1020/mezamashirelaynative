import React, { useState } from 'react'

interface ModalProps {
    open: boolean
    onClose: () => void
    title: string
    children: React.ReactNode
    maxWidth?: number
}

export function Modal({ open, onClose, title, children, maxWidth = 600 }: ModalProps) {
    if (!open) return null

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
                zIndex: 1000,
                padding: 16
            }}
            onClick={onClose}
        >
            <div
                style={{
                    width: '100%',
                    maxWidth,
                    background: 'white',
                    borderRadius: 16,
                    boxShadow: '0 24px 60px rgba(2,6,23,0.18)',
                    maxHeight: '90vh',
                    overflow: 'auto',
                    display: 'flex',
                    flexDirection: 'column'
                }}
                onClick={e => e.stopPropagation()}
            >
                <div style={{
                    padding: '20px 24px',
                    borderBottom: '1px solid #e5e7eb',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                }}>
                    <h2 style={{ margin: 0, fontSize: 20, fontWeight: 600 }}>{title}</h2>
                    <button
                        onClick={onClose}
                        style={{
                            background: 'none',
                            border: 'none',
                            fontSize: 24,
                            cursor: 'pointer',
                            color: '#9ca3af',
                            padding: 0,
                            width: 32,
                            height: 32,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center'
                        }}
                    >
                        ×
                    </button>
                </div>
                <div style={{ flex: 1, overflow: 'auto' }}>
                    {children}
                </div>
            </div>
        </div>
    )
}
