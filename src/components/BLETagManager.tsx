/**
 * BLETagManager - BLE タグの登録・管理・ステップ紐づけ UI
 */

import React, { useState } from 'react';
import { useBLEContext } from '../services/BLEProvider';
import { listMissions, listMissionSteps } from '../services/localStore';
import { useAuth } from '../services/auth';

export function BLETagManager() {
  const { user } = useAuth();
  const {
    tags,
    isScanning,
    error,
    isBluetoothAvailable,
    scanAndPair,
    removeTag,
    linkTagToStep,
    renameTag,
    reconnectAll,
  } = useBLEContext();

  const [missions, setMissions] = useState<any[]>([]);
  const [steps, setSteps] = useState<Record<string, any[]>>({});
  const [editingTag, setEditingTag] = useState<string | null>(null);
  const [newName, setNewName] = useState('');

  // ミッションとステップを読み込み
  React.useEffect(() => {
    if (!user) return;
    (async () => {
      const m = await listMissions(user.uid);
      setMissions(m);
      const stepsMap: Record<string, any[]> = {};
      for (const mission of m) {
        stepsMap[mission.id] = await listMissionSteps(mission.id);
      }
      setSteps(stepsMap);
    })();
  }, [user]);

  const handleScan = async () => {
    const tag = await scanAndPair();
    if (tag) {
      console.log('Paired tag:', tag);
    }
  };

  const handleRename = (tag_id: string) => {
    if (newName.trim()) {
      renameTag(tag_id, newName.trim());
      setEditingTag(null);
      setNewName('');
    }
  };

  if (!isBluetoothAvailable) {
    return (
      <div style={{ padding: 16, background: '#fff9e6', borderRadius: 12, marginBottom: 16 }}>
        <p style={{ margin: 0, color: '#b87503' }}>
          ⚠️ このブラウザは Web Bluetooth API に対応していません。
          Chrome/Edge (デスクトップ・Android) をお試しください。
        </p>
      </div>
    );
  }

  return (
    <div style={{ padding: 16, background: '#f5f5f7', borderRadius: 12 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
        <h3 style={{ margin: 0, fontSize: 18, fontWeight: 600 }}>BLE タグ管理</h3>
        <button
          onClick={handleScan}
          disabled={isScanning}
          style={{
            padding: '6px 12px',
            background: isScanning ? '#ccc' : '#007aff',
            color: 'white',
            border: 'none',
            borderRadius: 8,
            fontSize: 14,
            fontWeight: 500,
            cursor: isScanning ? 'not-allowed' : 'pointer',
          }}
        >
          {isScanning ? 'スキャン中...' : '+ タグを追加'}
        </button>
        {tags.length > 0 && (
          <button
            onClick={reconnectAll}
            style={{
              padding: '6px 12px',
              background: '#34c759',
              color: 'white',
              border: 'none',
              borderRadius: 8,
              fontSize: 14,
              fontWeight: 500,
              cursor: 'pointer',
            }}
          >
            🔄 再接続
          </button>
        )}
      </div>

      {error && (
        <div style={{ padding: 12, background: '#ffe6e6', borderRadius: 8, marginBottom: 16 }}>
          <p style={{ margin: 0, color: '#d32f2f', fontSize: 14 }}>{error}</p>
        </div>
      )}

      {tags.length === 0 ? (
        <p style={{ margin: 0, color: '#666', fontSize: 14 }}>
          BLE タグが登録されていません。「+ タグを追加」ボタンでスキャンしてください。
        </p>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {tags.map((tag) => (
            <div
              key={tag.tag_id}
              style={{
                padding: 12,
                background: 'white',
                borderRadius: 8,
                boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
              }}
            >
              {/* タグ名 */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                {editingTag === tag.tag_id ? (
                  <>
                    <input
                      type="text"
                      value={newName}
                      onChange={(e) => setNewName(e.target.value)}
                      placeholder="タグ名"
                      style={{
                        flex: 1,
                        padding: '4px 8px',
                        border: '1px solid #ddd',
                        borderRadius: 6,
                        fontSize: 14,
                      }}
                    />
                    <button
                      onClick={() => handleRename(tag.tag_id)}
                      style={{
                        padding: '4px 8px',
                        background: '#007aff',
                        color: 'white',
                        border: 'none',
                        borderRadius: 6,
                        fontSize: 12,
                        cursor: 'pointer',
                      }}
                    >
                      保存
                    </button>
                    <button
                      onClick={() => {
                        setEditingTag(null);
                        setNewName('');
                      }}
                      style={{
                        padding: '4px 8px',
                        background: '#ccc',
                        color: 'white',
                        border: 'none',
                        borderRadius: 6,
                        fontSize: 12,
                        cursor: 'pointer',
                      }}
                    >
                      キャンセル
                    </button>
                  </>
                ) : (
                  <>
                    <strong style={{ flex: 1, fontSize: 16 }}>{tag.name}</strong>
                    <button
                      onClick={() => {
                        setEditingTag(tag.tag_id);
                        setNewName(tag.name);
                      }}
                      style={{
                        padding: '4px 8px',
                        background: '#f0f0f0',
                        color: '#333',
                        border: 'none',
                        borderRadius: 6,
                        fontSize: 12,
                        cursor: 'pointer',
                      }}
                    >
                      ✏️
                    </button>
                    <button
                      onClick={() => removeTag(tag.tag_id)}
                      style={{
                        padding: '4px 8px',
                        background: '#ff3b30',
                        color: 'white',
                        border: 'none',
                        borderRadius: 6,
                        fontSize: 12,
                        cursor: 'pointer',
                      }}
                    >
                      削除
                    </button>
                  </>
                )}
              </div>

              {/* タグ情報 */}
              <div style={{ fontSize: 12, color: '#666', marginBottom: 8 }}>
                ID: {tag.tag_id}
                {tag.last_seen && (
                  <span style={{ marginLeft: 8 }}>
                    最終検出: {new Date(tag.last_seen).toLocaleString('ja-JP')}
                  </span>
                )}
              </div>

              {/* ステップ紐づけ */}
              <div>
                <label style={{ fontSize: 13, fontWeight: 500, display: 'block', marginBottom: 4 }}>
                  紐づけるステップ:
                </label>
                <select
                  value={tag.mission_step_id || ''}
                  onChange={(e) => linkTagToStep(tag.tag_id, e.target.value)}
                  style={{
                    width: '100%',
                    padding: '6px 8px',
                    border: '1px solid #ddd',
                    borderRadius: 6,
                    fontSize: 14,
                    background: 'white',
                  }}
                >
                  <option value="">（未選択）</option>
                  {missions.map((mission) => (
                    <optgroup key={mission.id} label={mission.name}>
                      {(steps[mission.id] || []).map((step: any) => (
                        <option key={step.id} value={step.id}>
                          {step.label}
                        </option>
                      ))}
                    </optgroup>
                  ))}
                </select>
              </div>
            </div>
          ))}
        </div>
      )}

      <div style={{ marginTop: 16, fontSize: 12, color: '#666' }}>
        <p style={{ margin: 0 }}>
          💡 BLE タグをスキャンして登録し、ミッションステップに紐づけてください。
          タグからイベントが送信されると、自動的にステップが完了します。
        </p>
      </div>
    </div>
  );
}
