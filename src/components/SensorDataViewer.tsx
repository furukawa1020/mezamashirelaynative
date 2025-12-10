/**
 * SensorDataViewer - センサデータの統計と履歴表示
 */

import React, { useEffect, useState } from 'react';
import { listTodaySessionsByUser, listSessionSteps } from '../services/localStore';

interface SensorStats {
  totalEvents: number;
  eventTypes: Record<string, number>;
  avgDuration: number;
  successRate: number;
  tagUsage: Record<string, number>;
}

interface SensorDataViewerProps {
  user: any;
}

export function SensorDataViewer({ user }: SensorDataViewerProps) {
  const [stats, setStats] = useState<SensorStats | null>(null);
  const [recentEvents, setRecentEvents] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!user) return;
    loadData();
  }, [user]);

  const loadData = async () => {
    if (!user) return;
    setLoading(true);
    try {
      // 今日のセッション取得
      const sessions = await listTodaySessionsByUser(user.uid);

      // 全ステップ取得
      const allSteps: any[] = [];
      for (const session of sessions) {
        const steps = await listSessionSteps(session.id);
        allSteps.push(...steps);
      }

      // BLE データがあるステップのみフィルタ
      const bleSteps = allSteps.filter((s) => s.ble_tag_id);

      // 統計計算
      const totalEvents = bleSteps.length;
      const eventTypes: Record<string, number> = {};
      const tagUsage: Record<string, number> = {};
      let totalDuration = 0;
      let durationCount = 0;
      let successCount = 0;

      bleSteps.forEach((step) => {
        // イベントタイプ集計
        if (step.ble_event) {
          eventTypes[step.ble_event] = (eventTypes[step.ble_event] || 0) + 1;
        }

        // タグ使用回数
        if (step.ble_tag_id) {
          tagUsage[step.ble_tag_id] = (tagUsage[step.ble_tag_id] || 0) + 1;
        }

        // 平均時間
        if (step.duration_ms) {
          totalDuration += step.duration_ms;
          durationCount++;
        }

        // 成功率
        if (step.result === 'success') {
          successCount++;
        }
      });

      const avgDuration = durationCount > 0 ? totalDuration / durationCount : 0;
      const successRate = totalEvents > 0 ? (successCount / totalEvents) * 100 : 0;

      setStats({
        totalEvents,
        eventTypes,
        avgDuration,
        successRate,
        tagUsage,
      });

      // 最新5件
      setRecentEvents(bleSteps.slice(-5).reverse());
    } catch (error) {
      console.error('Failed to load sensor data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!user) return null;
  if (loading) return <div>読み込み中...</div>;
  if (!stats) return null;

  return (
    <div style={{ marginTop: 24, padding: 16, background: '#f8f9fa', borderRadius: 8 }}>
      <h3 style={{ fontSize: 18, marginBottom: 16 }}>📊 センサデータ統計（今日）</h3>

      {/* 統計サマリー */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 12, marginBottom: 16 }}>
        <div style={{ padding: 12, background: 'white', borderRadius: 6 }}>
          <div style={{ fontSize: 12, color: '#666' }}>総イベント数</div>
          <div style={{ fontSize: 24, fontWeight: 600 }}>{stats.totalEvents}</div>
        </div>
        <div style={{ padding: 12, background: 'white', borderRadius: 6 }}>
          <div style={{ fontSize: 12, color: '#666' }}>成功率</div>
          <div style={{ fontSize: 24, fontWeight: 600 }}>{stats.successRate.toFixed(1)}%</div>
        </div>
        <div style={{ padding: 12, background: 'white', borderRadius: 6 }}>
          <div style={{ fontSize: 12, color: '#666' }}>平均所要時間</div>
          <div style={{ fontSize: 24, fontWeight: 600 }}>{(stats.avgDuration / 1000).toFixed(1)}秒</div>
        </div>
      </div>

      {/* イベントタイプ別 */}
      <div style={{ marginBottom: 16 }}>
        <h4 style={{ fontSize: 14, marginBottom: 8 }}>イベントタイプ別</h4>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {Object.entries(stats.eventTypes).map(([type, count]) => (
            <div key={type} style={{ padding: '6px 12px', background: 'white', borderRadius: 4, fontSize: 12 }}>
              {type}: <strong>{count}</strong>回
            </div>
          ))}
        </div>
      </div>

      {/* タグ使用回数 */}
      <div style={{ marginBottom: 16 }}>
        <h4 style={{ fontSize: 14, marginBottom: 8 }}>タグ別使用回数</h4>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {Object.entries(stats.tagUsage).map(([tag, count]) => (
            <div key={tag} style={{ padding: '6px 12px', background: 'white', borderRadius: 4, fontSize: 12 }}>
              {tag}: <strong>{count}</strong>回
            </div>
          ))}
        </div>
      </div>

      {/* 最近のイベント */}
      <div>
        <h4 style={{ fontSize: 14, marginBottom: 8 }}>最近のイベント</h4>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {recentEvents.map((event, i) => (
            <div key={i} style={{ padding: 10, background: 'white', borderRadius: 4, fontSize: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontWeight: 600 }}>{event.ble_event}</span>
                <span style={{ color: '#666' }}>
                  {event.duration_ms ? `${(event.duration_ms / 1000).toFixed(1)}秒` : '-'}
                </span>
              </div>
              <div style={{ color: '#666', fontSize: 11 }}>
                タグ: {event.ble_tag_id} | 信頼度: {(event.ble_confidence * 100).toFixed(0)}%
              </div>
            </div>
          ))}
        </div>
      </div>

      <button
        onClick={loadData}
        style={{ marginTop: 12, padding: '8px 16px', background: '#007bff', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}
      >
        🔄 更新
      </button>
    </div>
  );
}
