import React, { useState } from 'react'
import usePageMeta from '../hooks/usePageMeta'
import { useAuth } from '../services/auth'
import { createGroup, joinGroup, listGroupMembers, getGroup, listTodaySessionsByGroup, getGroupDailyStatus } from '../services/localStore'
import Skeleton from '../components/Skeleton'

type Member = { id: string; user_id: string }

export default function Groups() {
  usePageMeta('グループ', 'グループを作成・参加して一緒に起きよう')
  const { user } = useAuth()
  const [name, setName] = useState('')
  const [mode, setMode] = useState<'RACE' | 'ALL'>('RACE')
  const [joinId, setJoinId] = useState('')

  const onCreate = async () => {
    if (!user) return
    const gid = await createGroup(user.uid, name, mode)
    alert('グループ作成: ' + gid)
    setName('')
  }

  const onJoin = async () => {
    if (!user) return
    try {
      await joinGroup(user.uid, joinId)
      alert('参加しました')
      setJoinId('')
    } catch (e: any) {
      alert('参加失敗: ' + e.message)
    }
  }

  const [loadedGroup, setLoadedGroup] = useState<any>(null)
  const [members, setMembers] = useState<Member[]>([])
  const [todaySessions, setTodaySessions] = useState<any[]>([])
  const [dailyStatus, setDailyStatus] = useState<any>(null)
  const [loading, setLoading] = useState<boolean>(false)

  const loadGroup = async (gid?: string) => {
    const id = gid || prompt('読み込むグループIDを入力')
    if (!id) return
    try {
      setLoading(true)
      const g = await getGroup(id)
      setLoadedGroup(g)
      const m = await listGroupMembers(id)
      setMembers(m)
      const s = await listTodaySessionsByGroup(id)
      setTodaySessions(s)
      const ds = await getGroupDailyStatus(id)
      setDailyStatus(ds)
    } finally { setLoading(false) }
  }

  return (
    <div className="floating">
      <div className="card">
        <h3>新しいグループを作成</h3>
        <label className="small muted">グループ名</label>
        <input className="input" value={name} onChange={e => setName(e.target.value)} placeholder="例: 早起き部" />
        <label className="small muted" style={{ marginTop: 8 }}>モード</label>
        <select className="input" value={mode} onChange={e => setMode(e.target.value as any)}>
          <option value="RACE">RACE (競争)</option>
          <option value="ALL">ALL (全員達成)</option>
        </select>
        <div style={{ marginTop: 12, textAlign: 'right' }}>
          <button className="button" onClick={onCreate}>作成する</button>
        </div>
      </div>

      <div className="card">
        <h3>招待で参加</h3>
        <label className="small muted">招待コード / グループID</label>
        <input className="input" value={joinId} onChange={e => setJoinId(e.target.value)} placeholder="グループIDを入力" />
        <div style={{ marginTop: 12, textAlign: 'right' }}>
          <button className="button" onClick={onJoin}>参加する</button>
          <button className="button" style={{ marginLeft: 8, background: '#3a3a3c' }} onClick={() => loadGroup(joinId)}>表示確認</button>
        </div>
      </div>

      {loadedGroup && (
        <div className="card" style={{ border: '1px solid var(--accent)' }}>
          <h3 style={{ color: 'var(--accent)' }}>{loadedGroup.name} <span className="small muted">({loadedGroup.mode})</span></h3>
          <div className="small muted">ID: {loadedGroup.id}</div>

          <div style={{ marginTop: 16 }}>
            <h4 style={{ marginBottom: 8 }}>メンバー ({members.length})</h4>
            {loading ? <Skeleton lines={3} /> : (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                {members.map(m => <div key={m.id} style={{ background: '#3a3a3c', padding: '4px 8px', borderRadius: 8, fontSize: 12 }}>{m.user_id}</div>)}
              </div>
            )}
          </div>

          <div style={{ marginTop: 16 }}>
            <h4 style={{ marginBottom: 8 }}>今日のセッション</h4>
            {loading ? <Skeleton lines={2} /> : todaySessions.length === 0 ? <div className="small muted">まだ開始していません</div> : (
              todaySessions.map(s => (
                <div key={s.id} style={{ padding: '8px 0', borderBottom: '1px solid #3a3a3c', display: 'flex', justifyContent: 'space-between' }}>
                  <span>{s.user_id}</span>
                  <span style={{ color: s.status === 'completed' ? 'var(--success)' : 'var(--text-sub)' }}>
                    {s.status === 'completed' ? '完了 🎉' : '進行中 🏃'} {s.rank ? `(Rank ${s.rank})` : ''}
                  </span>
                </div>
              ))
            )}
          </div>

          <div style={{ marginTop: 16, padding: 12, background: '#3a3a3c', borderRadius: 8 }}>
            <h4 style={{ marginBottom: 4 }}>今日のステータス</h4>
            {loading ? <Skeleton lines={1} /> : (dailyStatus ? (
              <div>
                <div>全員達成: {dailyStatus.all_cleared ? '✅ 達成！' : 'まだ'}</div>
                <div>連続達成: {dailyStatus.clear_streak}日</div>
              </div>
            ) : <div className="small muted">記録なし</div>)}
          </div>
        </div>
      )}
    </div>
  )
}
