import React, { useState } from 'react'
import { IconTouch, IconShake, IconScan, IconMapPin, IconQRCode, IconCheck } from './Icons'

interface StepTypeSelectorProps {
    onSelect: (type: 'manual' | 'shake' | 'qr' | 'gps' | 'ai_detect', config: any) => void
    onCancel: () => void
}

export function StepTypeSelector({ onSelect, onCancel }: StepTypeSelectorProps) {
    const [selectedType, setSelectedType] = useState<'manual' | 'shake' | 'qr' | 'gps' | 'ai_detect' | null>(null)
    const [config, setConfig] = useState<any>({})

    const stepTypes = [
        {
            type: 'manual' as const,
            icon: <IconTouch size={32} />,
            title: '手動完了',
            description: 'ボタンをタップして完了',
            color: '#10b981'
        },
        {
            type: 'shake' as const,
            icon: <IconShake size={32} />,
            title: 'シェイク',
            description: 'スマホを振って完了',
            color: '#f59e0b',
            configFields: [
                { key: 'count', label: 'シェイク回数', type: 'number', default: 20 }
            ]
        },
        {
            type: 'ai_detect' as const,
            icon: <IconScan size={32} />,
            title: 'AI物体検出',
            description: 'カメラで物を検出',
            color: '#8b5cf6',
            configFields: [
                {
                    key: 'targetLabel', label: '検出する物体', type: 'text', default: 'cup',
                    hint: '例: cup, bottle, person, cell phone, book'
                }
            ]
        },
        {
            type: 'gps' as const,
            icon: <IconMapPin size={32} />,
            title: 'GPS移動',
            description: '指定距離を歩く',
            color: '#3b82f6',
            configFields: [
                { key: 'distance', label: '移動距離（メートル）', type: 'number', default: 100 }
            ]
        },
        {
            type: 'qr' as const,
            icon: <IconQRCode size={32} />,
            title: 'QRコード',
            description: 'QR/バーコードをスキャン',
            color: '#ec4899',
            configFields: [
                { key: 'targetValue', label: '正解の値（空欄=何でもOK）', type: 'text', default: '' }
            ]
        }
    ]

    const handleConfirm = () => {
        if (!selectedType) return

        const selectedStepType = stepTypes.find(t => t.type === selectedType)
        const finalConfig: any = {}

        if (selectedStepType?.configFields) {
            selectedStepType.configFields.forEach(field => {
                finalConfig[field.key] = config[field.key] !== undefined ? config[field.key] : field.default
            })
        }

        onSelect(selectedType, finalConfig)
    }

    return (
        <div style={{ padding: 16 }}>
            <h3 style={{ margin: '0 0 16px 0', fontSize: 18 }}>ステップタイプを選択</h3>

            <div style={{ display: 'grid', gap: 12, marginBottom: 20 }}>
                {stepTypes.map(stepType => (
                    <div
                        key={stepType.type}
                        onClick={() => setSelectedType(stepType.type)}
                        style={{
                            padding: 16,
                            border: `2px solid ${selectedType === stepType.type ? stepType.color : '#e5e7eb'}`,
                            borderRadius: 12,
                            cursor: 'pointer',
                            background: selectedType === stepType.type ? `${stepType.color}10` : 'white',
                            transition: 'all 0.2s'
                        }}
                    >
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                            <div style={{ color: stepType.color }}>{stepType.icon}</div>
                            <div style={{ flex: 1 }}>
                                <div style={{ fontWeight: 600, fontSize: 16, marginBottom: 4 }}>
                                    {stepType.title}
                                </div>
                                <div style={{ fontSize: 13, color: '#6b7280' }}>
                                    {stepType.description}
                                </div>
                            </div>
                            {selectedType === stepType.type && (
                                <div style={{
                                    width: 24,
                                    height: 24,
                                    borderRadius: '50%',
                                    background: stepType.color,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    color: 'white',
                                    fontSize: 14
                                }}>
                                    <IconCheck size={14} />
                                </div>
                            )}
                        </div>
                    </div>
                ))}
            </div>

            {selectedType && stepTypes.find(t => t.type === selectedType)?.configFields && (
                <div style={{
                    padding: 16,
                    background: '#f9fafb',
                    borderRadius: 8,
                    marginBottom: 16
                }}>
                    <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>設定</div>
                    {stepTypes.find(t => t.type === selectedType)!.configFields!.map(field => (
                        <div key={field.key} style={{ marginBottom: 12 }}>
                            <label style={{ display: 'block', fontSize: 13, marginBottom: 4, color: '#374151' }}>
                                {field.label}
                            </label>
                            <input
                                type={field.type}
                                className="input"
                                value={config[field.key] !== undefined ? config[field.key] : field.default}
                                onChange={e => setConfig({ ...config, [field.key]: field.type === 'number' ? parseInt(e.target.value) || 0 : e.target.value })}
                                style={{ width: '100%' }}
                            />
                            {field.hint && (
                                <div style={{ fontSize: 12, color: '#9ca3af', marginTop: 4 }}>
                                    {field.hint}
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            )}

            <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
                <button
                    className="button"
                    onClick={onCancel}
                    style={{ background: '#f3f4f6', color: '#374151' }}
                >
                    キャンセル
                </button>
                <button
                    className="button"
                    onClick={handleConfirm}
                    disabled={!selectedType}
                    style={{
                        background: selectedType ? '#0a84ff' : '#9ca3af',
                        cursor: selectedType ? 'pointer' : 'not-allowed'
                    }}
                >
                    追加
                </button>
            </div>
        </div>
    )
}
