// Simple localStorage-backed data store to emulate Firestore API for local-first mode
// Not a full replacement — small, synchronous-ish helpers used by the app
type AnyObj = Record<string, any>

function load(key: string) {
  try { const raw = localStorage.getItem(key); return raw ? JSON.parse(raw) : [] } catch (e) { return [] }
}
function save(key: string, data: any) { try { localStorage.setItem(key, JSON.stringify(data)) } catch (e) { } }
function genId(prefix = 'l') { return prefix + '-' + Math.random().toString(36).slice(2, 9) }

const KEYS = {
  missions: 'mz_store_missions',
  mission_steps: 'mz_store_mission_steps',
  groups: 'mz_store_groups',
  group_members: 'mz_store_group_members',
  sessions: 'mz_store_sessions',
  session_steps: 'mz_store_session_steps',
  group_daily_status: 'mz_store_group_daily_status'
}

// Missions
export async function createMission(userId: string, data: { name: string; wake_time: string; repeat_rule?: string }) {
  const all = load(KEYS.missions)
  const id = genId('m')
  const rec = { id, user_id: userId, name: data.name, wake_time: data.wake_time, repeat_rule: data.repeat_rule || 'everyday', created_at: Date.now() }
  all.unshift(rec)
  save(KEYS.missions, all)
  return id
}
export async function createMissionStep(missionId: string, data: { label: string; order?: number; type?: string; action_type?: 'manual' | 'shake' | 'qr' | 'gps'; action_config?: any; nfc_tag_id?: string; ble_event_type?: string }) {
  const all = load(KEYS.mission_steps)
  const id = genId('ms')
  const rec = {
    id,
    mission_id: missionId,
    label: data.label,
    order: data.order || 0,
    type: data.type || 'manual',
    action_type: data.action_type || 'manual',
    action_config: data.action_config || {},
    nfc_tag_id: data.nfc_tag_id || null,
    ble_event_type: data.ble_event_type || null
  }
  all.push(rec)
  save(KEYS.mission_steps, all)
  return id
}

export async function listMissionSteps(missionId: string) {
  const all = load(KEYS.mission_steps)
  return all.filter((r: AnyObj) => r.mission_id === missionId).sort((a: AnyObj, b: AnyObj) => (a.order || 0) - (b.order || 0))
}

export async function deleteMission(missionId: string) {
  const all = load(KEYS.missions)
  const next = all.filter((r: AnyObj) => r.id !== missionId)
  save(KEYS.missions, next)

  // cascade delete steps
  const steps = load(KEYS.mission_steps)
  const nextSteps = steps.filter((r: AnyObj) => r.mission_id !== missionId)
  save(KEYS.mission_steps, nextSteps)
}

export async function deleteMissionStep(stepId: string) {
  const all = load(KEYS.mission_steps)
  const next = all.filter((r: AnyObj) => r.id !== stepId)
  save(KEYS.mission_steps, next)
}

// Groups
export async function createGroup(userId: string, name: string, mode: 'RACE' | 'ALL') {
  const all = load(KEYS.groups)
  const id = genId('g')
  const rec = { id, name, mode, owner_id: userId, created_at: Date.now() }
  all.unshift(rec)
  save(KEYS.groups, all)

  // add membership
  await setDocGroupMember(id, userId)
  return id
}

async function setDocGroupMember(groupId: string, userId: string) {
  const all = load(KEYS.group_members)
  const rec = { id: `${groupId}_${userId}`, group_id: groupId, user_id: userId, joined_at: Date.now() }
  // replace if exists
  const idx = all.findIndex((r: AnyObj) => r.id === rec.id)
  if (idx >= 0) all[idx] = rec
  else all.push(rec)
  save(KEYS.group_members, all)
}

export async function joinGroup(userId: string, groupId: string) {
  await setDocGroupMember(groupId, userId)
}

export async function getGroup(groupId: string) {
  const all = load(KEYS.groups)
  const g = all.find((r: AnyObj) => r.id === groupId)
  return g || null
}

export async function listGroupMembers(groupId: string) {
  const all = load(KEYS.group_members)
  return all.filter((r: AnyObj) => r.group_id === groupId)
}

// Sessions
export async function startSession(userId: string, missionId: string, groupId?: string) {
  const sessions = load(KEYS.sessions)
  const id = genId('s')
  const today = new Date().toISOString().slice(0, 10)
  const rec = { id, user_id: userId, group_id: groupId || null, mission_id: missionId, date: today, status: 'in_progress', started_at: Date.now() }
  sessions.push(rec)
  save(KEYS.sessions, sessions)

  // create session steps from mission steps
  try {
    const ms = await listMissionSteps(missionId)
    const ssteps = load(KEYS.session_steps)
    for (const m of ms) {
      ssteps.push({
        id: genId('ss'),
        session_id: id,
        mission_step_id: m.id,
        label: m.label || '',
        action_type: m.action_type || 'manual',
        action_config: m.action_config || {},
        started_at: Date.now(),
        finished_at: null,
        result: 'not_started',
        lap_ms: null,
        order: m.order || 0
      })
    }
    save(KEYS.session_steps, ssteps)
  } catch (e) { }

  return id
}
// ... (rest of the file)

// Seed sample data for a user (useful for demos)
export async function seedSampleData(userId: string) {
  // create a sample mission with 3 steps
  const missionId = await createMission(userId, { name: '朝のストレッチ', wake_time: '07:00' })
  await createMissionStep(missionId, { label: 'ベッドから出る', order: 0, action_type: 'shake', action_config: { count: 20 } })
  await createMissionStep(missionId, { label: '顔を洗う', order: 1, action_type: 'manual' })
  await createMissionStep(missionId, { label: '深呼吸して完了', order: 2, action_type: 'manual' })

  // sample group
  const groupId = await createGroup(userId, 'テストグループ', 'ALL')
  await joinGroup(userId, groupId)
  return { missionId, groupId }
}

export async function finishSession(sessionId: string, finishedAt?: any) {
  const sessions = load(KEYS.sessions)
  const idx = sessions.findIndex((r: AnyObj) => r.id === sessionId)
  if (idx >= 0) { sessions[idx].status = 'completed'; sessions[idx].finished_at = finishedAt || Date.now(); save(KEYS.sessions, sessions) }
}

export async function listTodaySessionsByGroup(groupId: string) {
  const today = new Date().toISOString().slice(0, 10)
  const sessions = load(KEYS.sessions)
  return sessions.filter((r: AnyObj) => r.group_id === groupId && r.date === today)
}

export async function getGroupDailyStatus(groupId: string, date?: string) {
  const d = date || new Date().toISOString().slice(0, 10)
  const all = load(KEYS.group_daily_status)
  return all.find((r: AnyObj) => r.group_id === groupId && r.date === d) || null
}

export async function finishSessionAndCompute(sessionId: string) {
  // mark session completed and compute simple RACE/ALL results
  await finishSession(sessionId)
  const sessions = load(KEYS.sessions)
  const s = sessions.find((r: AnyObj) => r.id === sessionId)
  if (!s) return
  const groupId = s.group_id
  const date = s.date
  if (!groupId) return

  const group = await getGroup(groupId)
  if (!group) return

  if (group.mode === 'RACE') {
    const completed = load(KEYS.sessions).filter((r: AnyObj) => r.group_id === groupId && r.date === date && r.status === 'completed').sort((a: AnyObj, b: AnyObj) => (a.finished_at || 0) - (b.finished_at || 0))
    const ids = completed.map((c: AnyObj) => c.id)
    const rank = ids.indexOf(sessionId) + 1
    if (rank > 0) {
      const sessionsAll = load(KEYS.sessions)
      const idx = sessionsAll.findIndex((r: AnyObj) => r.id === sessionId)
      if (idx >= 0) { sessionsAll[idx].rank = rank; save(KEYS.sessions, sessionsAll) }
    }
  }

  if (group.mode === 'ALL') {
    const members = (await listGroupMembers(groupId)).map((m: AnyObj) => m.user_id)
    const cleared = load(KEYS.sessions).filter((r: AnyObj) => r.group_id === groupId && r.date === date && r.status === 'completed').map((r: AnyObj) => r.user_id)
    const allCleared = members.every((id: string) => cleared.includes(id))
    const gds = load(KEYS.group_daily_status)
    const key = `${groupId}_${date}`
    const prev = gds.find((x: AnyObj) => x.id === key)
    let streak = 0
    if (allCleared) { streak = (prev?.clear_streak || 0) + 1 }
    const rec = { id: key, group_id: groupId, date, all_cleared: !!allCleared, cleared_members: cleared, last_clear_member: s.user_id || null, clear_streak: streak }
    // replace or push
    const idx = gds.findIndex((x: AnyObj) => x.id === key)
    if (idx >= 0) gds[idx] = rec; else gds.push(rec)
    save(KEYS.group_daily_status, gds)
  }
}

export async function listTodaySessionsByUser(userId: string) {
  const today = new Date().toISOString().slice(0, 10)
  const sessions = load(KEYS.sessions)
  return sessions.filter((r: AnyObj) => r.user_id === userId && r.date === today)
}

export async function listSessionSteps(sessionId: string) {
  const all = load(KEYS.session_steps)
  return all.filter((r: AnyObj) => r.session_id === sessionId).sort((a: AnyObj, b: AnyObj) => (a.order || 0) - (b.order || 0))
}

export async function completeSessionStep(sessionStepId: string, bleData?: {
  ble_tag_id?: string;
  ble_event?: string;
  ble_confidence?: number;
  duration_ms?: number;
}) {
  const all = load(KEYS.session_steps)
  const idx = all.findIndex((r: AnyObj) => r.id === sessionStepId)
  if (idx < 0) return

  const step = all[idx]
  if (!step) return
  const sessionId = step.session_id
  if (!sessionId) return

  // 同じセッションの全ステップを取得
  const sessionSteps = all.filter((r: AnyObj) => r.session_id === sessionId).sort((a: AnyObj, b: AnyObj) => (a.order || 0) - (b.order || 0))

  // 最後のステップかどうかチェック
  const isLastStep = step.order === Math.max(...sessionSteps.map((s: AnyObj) => s.order || 0))

  if (isLastStep) {
    // 最後のステップ（ドア）の場合、すべての前のステップが完了していることを確認
    const incompletePrevSteps = sessionSteps.filter((s: AnyObj) => s.order < step.order && s.result !== 'success')
    if (incompletePrevSteps.length > 0) {
      throw new Error('すべてのステップを完了してから、ドアを開けてください')
    }
  }

  // ステップを完了
  all[idx].finished_at = Date.now();
  all[idx].result = 'success';
  if (bleData) {
    all[idx].ble_tag_id = bleData.ble_tag_id;
    all[idx].ble_event = bleData.ble_event;
    all[idx].ble_confidence = bleData.ble_confidence;
    all[idx].duration_ms = bleData.duration_ms;
  }
  save(KEYS.session_steps, all);

  // check if any remaining not-success steps
  const rem = all.filter((r: AnyObj) => r.session_id === sessionId && r.result !== 'success')
  if (rem.length === 0) {
    try { await finishSessionAndCompute(sessionId) } catch (e) { }
  }
}

// Export all stored data as a single object
export function exportAll() {
  const out: AnyObj = {}
  for (const k of Object.keys(KEYS)) {
    out[k] = load((KEYS as any)[k])
  }
  return out
}

// Replace store with imported data (careful: overwrites existing)
export function importAll(data: AnyObj) {
  try {
    for (const k of Object.keys(KEYS)) {
      const key = (KEYS as any)[k]
      if (data[k] !== undefined) { save(key, data[k]) }
    }
    return true
  } catch (e) { return false }
}

// Backup helpers
export function saveBackup() {
  try {
    const snap = exportAll()
    const key = 'mz_backup_latest'
    localStorage.setItem(key, JSON.stringify({ created_at: Date.now(), snap }))
    return true
  } catch (e) { return false }
}

export function getLatestBackup() {
  try {
    const raw = localStorage.getItem('mz_backup_latest')
    return raw ? JSON.parse(raw) : null
  } catch (e) { return null }
}

export { }
