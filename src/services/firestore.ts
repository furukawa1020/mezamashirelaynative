import { initializeApp } from 'firebase/app'
import { getFirestore, collection, addDoc, doc, setDoc, getDocs, query, where, orderBy, updateDoc, serverTimestamp, getDoc } from 'firebase/firestore'
import * as local from './localStore'

const USE_FIREBASE = import.meta.env.VITE_USE_FIREBASE === '1'

// If Firebase is enabled at build/runtime, use the Firebase implementations below.
// Otherwise export the localStore functions as a drop-in replacement.

// Firebase-backed implementations
let firebaseDb: any = null

async function createMissionFirebase(userId: string, data: { name: string; wake_time: string; repeat_rule?: string }){
  const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'YOUR_API_KEY',
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'YOUR_AUTH_DOMAIN',
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'YOUR_PROJECT_ID',
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || undefined,
    appId: import.meta.env.VITE_FIREBASE_APP_ID || undefined
  }
  const app = initializeApp(firebaseConfig)
  firebaseDb = getFirestore(app)
  const col = collection(firebaseDb, 'missions')
  const docRef = await addDoc(col, {
    user_id: userId,
    name: data.name,
    wake_time: data.wake_time,
    repeat_rule: data.repeat_rule || 'everyday',
    created_at: serverTimestamp()
  })
  return docRef.id
}

async function listMissionsFirebase(userId:string){
  const q = query(collection(firebaseDb,'missions'), where('user_id','==',userId), orderBy('created_at','desc'))
  const snap = await getDocs(q)
  return snap.docs.map(d=>({ id:d.id, ...d.data() }))
}

async function createMissionStepFirebase(missionId:string, data:any){
  const col = collection(firebaseDb,'mission_steps')
  const docRef = await addDoc(col, {
    mission_id: missionId,
    label: data.label,
    order: data.order || 0,
    type: data.type || 'manual',
    nfc_tag_id: data.nfc_tag_id || null,
    ble_event_type: data.ble_event_type || null
  })
  return docRef.id
}

async function listMissionStepsFirebase(missionId:string){
  const q = query(collection(db,'mission_steps'), where('mission_id','==',missionId), orderBy('order','asc'))
  const snap = await getDocs(q)
  return snap.docs.map(d=>({ id:d.id, ...d.data() }))
}

async function createGroupFirebase(userId:string, name:string, mode:'RACE'|'ALL'){
  const col = collection(firebaseDb,'groups')
  const docRef = await addDoc(col, { name, mode, owner_id: userId, created_at: serverTimestamp() })
  await setDoc(doc(firebaseDb,'group_members', `${docRef.id}_${userId}`), { group_id: docRef.id, user_id: userId, joined_at: serverTimestamp() })
  return docRef.id
}

async function joinGroupFirebase(userId:string, groupId:string){
  await setDoc(doc(firebaseDb,'group_members', `${groupId}_${userId}`), { group_id: groupId, user_id: userId, joined_at: serverTimestamp() })
}

async function startSessionFirebase(userId:string, missionId:string, groupId?:string){
  const col = collection(firebaseDb,'sessions')
  const docRef = await addDoc(col, { user_id: userId, group_id: groupId||null, mission_id: missionId, date: new Date().toISOString().slice(0,10), status: 'in_progress', started_at: serverTimestamp() })
  const sessionId = docRef.id
  try{
    const ms = await listMissionStepsFirebase(missionId)
    for(const m of ms){
      await addDoc(collection(firebaseDb,'session_steps'), { session_id: sessionId, mission_step_id: m.id, label: (m as any).label||'', started_at: serverTimestamp(), finished_at: null, result: 'not_started', lap_ms: null, order: (m as any).order||0 })
    }
  }catch(e){}
  return sessionId
}

async function finishSessionFirebase(sessionId:string, finishedAt?:any){
  const ref = doc(firebaseDb,'sessions',sessionId)
  await updateDoc(ref, { status:'completed', finished_at: finishedAt || serverTimestamp() })
}

async function listTodaySessionsByGroupFirebase(groupId:string){
  const today = new Date().toISOString().slice(0,10)
  const q = query(collection(firebaseDb,'sessions'), where('group_id','==',groupId), where('date','==',today))
  const snap = await getDocs(q)
  return snap.docs.map(d=>({ id:d.id, ...d.data() }))
}

async function getGroupFirebase(groupId:string){
  const ref = doc(firebaseDb,'groups',groupId)
  const snap = await getDoc(ref)
  return snap.exists() ? { id:snap.id, ...snap.data() } : null
}

async function listGroupMembersFirebase(groupId:string){
  const q = query(collection(firebaseDb,'group_members'), where('group_id','==',groupId))
  const snap = await getDocs(q)
  return snap.docs.map(d=>({ id:d.id, ...d.data() }))
}

async function finishSessionAndComputeFirebase(sessionId:string){
  const sref = doc(db,'sessions',sessionId)
  const sSnap = await getDoc(sref)
  if(!sSnap.exists()) throw new Error('session not found')
  const sData:any = sSnap.data()
  const finishedAt = serverTimestamp()
  await updateDoc(sref, { status:'completed', finished_at: finishedAt })
  const groupId = sData.group_id
  const date = sData.date
  if(!groupId) return
  const group = await getGroupFirebase(groupId)
  if(!group) return
  if((group as any).mode === 'RACE'){
  const q = query(collection(firebaseDb,'sessions'), where('group_id','==',groupId), where('date','==',date), where('status','==','completed'), orderBy('finished_at','asc'))
  const snap = await getDocs(q)
    const ids = snap.docs.map(d=>d.id)
    const rank = ids.indexOf(sessionId) + 1
    if(rank>0){ await updateDoc(sref, { rank }) }
  }
  if((group as any).mode === 'ALL'){
    const members = await listGroupMembersFirebase(groupId)
    const memberIds = members.map((m:any)=>m.user_id)
  const q = query(collection(firebaseDb,'sessions'), where('group_id','==',groupId), where('date','==',date), where('status','==','completed'))
  const snap = await getDocs(q)
    const cleared = snap.docs.map(d=> (d.data() as any).user_id )
    const allCleared = memberIds.every(id=> cleared.includes(id))
  const gdsRef = doc(firebaseDb,'group_daily_status', `${groupId}_${date}`)
  const prevSnap = await getDoc(gdsRef)
    let streak = 0
    if(allCleared){
      if(prevSnap.exists()){ const prev = prevSnap.data() as any; streak = (prev.clear_streak || 0) + 1 } else { streak = 1 }
      await setDoc(gdsRef, { group_id: groupId, date, all_cleared: true, cleared_members: cleared, last_clear_member: sData.user_id || null, clear_streak: streak })
    }else{
      await setDoc(gdsRef, { group_id: groupId, date, all_cleared: false, cleared_members: cleared, last_clear_member: sData.user_id || null, clear_streak: 0 })
    }
  }
}

async function getGroupDailyStatusFirebase(groupId:string, date?:string){
  const d = date || new Date().toISOString().slice(0,10)
  const ref = doc(firebaseDb,'group_daily_status', `${groupId}_${d}`)
  const snap = await getDoc(ref)
  return snap.exists() ? { id:snap.id, ...snap.data() } : null
}

async function listTodaySessionsByUserFirebase(userId:string){
  const today = new Date().toISOString().slice(0,10)
  const q = query(collection(firebaseDb,'sessions'), where('user_id','==',userId), where('date','==',today))
  const snap = await getDocs(q)
  return snap.docs.map(d=>({ id:d.id, ...d.data() }))
}

async function listSessionStepsFirebase(sessionId:string){
  const q = query(collection(firebaseDb,'session_steps'), where('session_id','==',sessionId), orderBy('order','asc'))
  const snap = await getDocs(q)
  return snap.docs.map(d=>({ id:d.id, ...d.data() }))
}

async function completeSessionStepFirebase(sessionStepId:string, bleData?: {
  ble_tag_id?: string;
  ble_event?: string;
  ble_confidence?: number;
  duration_ms?: number;
}){
  const ref = doc(firebaseDb,'session_steps',sessionStepId)
  const snap = await getDoc(ref)
  if(!snap.exists()) return
  
  const sdata:any = snap.data()
  const sessionId = sdata.session_id
  if(!sessionId) return

  // 同じセッションの全ステップを取得
  const allStepsQuery = query(collection(firebaseDb,'session_steps'), where('session_id','==',sessionId), orderBy('order','asc'))
  const allStepsSnap = await getDocs(allStepsQuery)
  const sessionSteps = allStepsSnap.docs.map(d=>({ id:d.id, ...d.data() }))
  
  // 最後のステップかどうかチェック
  const maxOrder = Math.max(...sessionSteps.map((s:any)=>s.order||0))
  const isLastStep = sdata.order === maxOrder
  
  if (isLastStep) {
    // 最後のステップ（ドア）の場合、すべての前のステップが完了していることを確認
    const incompletePrevSteps = sessionSteps.filter((s:any)=> s.order < sdata.order && s.result !== 'success')
    if (incompletePrevSteps.length > 0) {
      throw new Error('すべてのステップを完了してから、ドアを開けてください')
    }
  }

  // ステップを完了
  const updateData: any = { finished_at: serverTimestamp(), result: 'success' }
  if (bleData) {
    updateData.ble_tag_id = bleData.ble_tag_id
    updateData.ble_event = bleData.ble_event
    updateData.ble_confidence = bleData.ble_confidence
    updateData.duration_ms = bleData.duration_ms
  }
  await updateDoc(ref, updateData)

  const q = query(collection(firebaseDb,'session_steps'), where('session_id','==',sessionId), where('result','!=','success'))
  const rem = await getDocs(q)
  if(rem.size === 0){ try{ await finishSessionAndComputeFirebase(sessionId) }catch(e){} }
}

// Export mapping: use Firebase implementations when enabled, otherwise use localStore
export const createMission = USE_FIREBASE ? createMissionFirebase : local.createMission
export const listMissions = USE_FIREBASE ? listMissionsFirebase : local.listMissions
export const createMissionStep = USE_FIREBASE ? createMissionStepFirebase : local.createMissionStep
export const listMissionSteps = USE_FIREBASE ? listMissionStepsFirebase : local.listMissionSteps
export const createGroup = USE_FIREBASE ? createGroupFirebase : local.createGroup
export const joinGroup = USE_FIREBASE ? joinGroupFirebase : local.joinGroup
export const startSession = USE_FIREBASE ? startSessionFirebase : local.startSession
export const finishSession = USE_FIREBASE ? finishSessionFirebase : local.finishSession
export const listTodaySessionsByGroup = USE_FIREBASE ? listTodaySessionsByGroupFirebase : local.listTodaySessionsByGroup
export const getGroup = USE_FIREBASE ? getGroupFirebase : local.getGroup
export const listGroupMembers = USE_FIREBASE ? listGroupMembersFirebase : local.listGroupMembers
export const finishSessionAndCompute = USE_FIREBASE ? finishSessionAndComputeFirebase : local.finishSessionAndCompute
export const getGroupDailyStatus = USE_FIREBASE ? getGroupDailyStatusFirebase : local.getGroupDailyStatus
export const listTodaySessionsByUser = USE_FIREBASE ? listTodaySessionsByUserFirebase : local.listTodaySessionsByUser
export const listSessionSteps = USE_FIREBASE ? listSessionStepsFirebase : local.listSessionSteps
export const completeSessionStep = USE_FIREBASE ? completeSessionStepFirebase : local.completeSessionStep

export const db = USE_FIREBASE ? firebaseDb : null

