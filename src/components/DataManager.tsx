import React, { useRef, useState } from 'react'
import * as local from '../services/localStore'
import { useToast } from './Toast'
import ShareModal from './ShareModal'
import AutoBackup from './AutoBackup'
import { migrateLocalToCloud } from '../services/migrate'

interface DataManagerProps {
  user: any;
}

export default function DataManager({ user }: DataManagerProps) {
  const fileRef = useRef<HTMLInputElement | null>(null)
  const { showToast } = useToast()
  const [shareOpen, setShareOpen] = useState(false)
  const [shareData, setShareData] = useState<string>('')

  const onExport = () => {
    try {
      const data = local.exportAll()
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = 'mezamashi-backup.json'
      a.click()
      URL.revokeObjectURL(url)
      showToast('エクスポート完了')
    } catch (e) { showToast('エクスポートに失敗しました') }
  }

  const onImportClick = () => fileRef.current?.click()

  const onFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return
    try {
      const txt = await f.text()
      const obj = JSON.parse(txt)
      const ok = local.importAll(obj)
      if (ok) showToast('インポート完了')
      else showToast('インポートに失敗しました')
    } catch (e) { showToast('ファイル読み込みに失敗しました') }
  }

  const onSeed = async () => {
    if (!user) { showToast('ログインが必要です'); return }
    try {
      await local.seedSampleData(user.uid)
      showToast('サンプルデータを作成しました')
    } catch (e) { showToast('サンプルデータの作成に失敗しました') }
  }

  const onShare = () => {
    const data = JSON.stringify(local.exportAll())
    setShareData(data)
    setShareOpen(true)
  }

  const onMigrate = async () => {
    if (!(import.meta.env.VITE_USE_FIREBASE === '1')) { showToast('Firebase が有効な場合のみ移行できます'); return }
    if (!user) { showToast('ログインが必要です'); return }
    try {
      await migrateLocalToCloud(user.uid)
      showToast('ローカルデータをクラウドに移行しました')
    } catch (e) { showToast('移行に失敗しました') }
  }

  return (
    <div style={{ marginTop: 12 }} className="card">
      <h4>データ管理（ローカルモード向け）</h4>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <button className="button" onClick={onExport}>エクスポート (JSON)</button>
        <button className="button" onClick={onImportClick}>インポート (JSON)</button>
        <input ref={fileRef} type="file" accept="application/json" style={{ display: 'none' }} onChange={onFile} />
        <button className="button" onClick={onSeed}>サンプルデータ投入</button>
        <button className="button" onClick={onShare}>QRで共有/表示</button>
        <button className="button" onClick={onMigrate}>ローカル→クラウドに移行</button>
      </div>
      <small className="muted">※ この操作は localStorage を直接変更します。バックアップをとってください。</small>
      <ShareModal open={shareOpen} data={shareData} onClose={() => setShareOpen(false)} />
      <AutoBackup />
    </div>
  )
}
