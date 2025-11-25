// import * as local from './localStore'
// import * as fs from './firestore'

// Migrate localStore data to Firestore (when Firebase enabled). This will create
// missions, steps, groups and memberships. Sessions are not migrated automatically to avoid duplicates.
export async function migrateLocalToCloud(userId: string) {
  // if(!(import.meta.env.VITE_USE_FIREBASE === '1')) throw new Error('Firebase disabled')
  throw new Error('Firebase migration is not available (firestore.ts missing)')
}

export default migrateLocalToCloud
