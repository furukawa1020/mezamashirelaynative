# めざましリレー — 実装ドキュメント

このドキュメントはローカル開発者・運用者向けに、現在の実装内容を細かくまとめたもの。
リポジトリ内の主要な設計判断、ファイル構成、各モジュールの責務、起動・ビルド手順、デプロイ、移行手順、トラブルシュートなどを含む。

## 目次
- 概要
- アーキテクチャ概要
- 主要ファイルとコンポーネント（責務とエンドポイント）
- サービス層（認証・データストア・サウンド）
- データモデル（shape）
- PWA とオフライン動作
- CI / CD（GitHub Actions）
- ローカル実行とビルド検証手順
- デプロイ（Netlify）
- ローカル→クラウド移行の流れ
- セキュリティと運用上の注意
- よくあるトラブルと対処法
- 今後の推奨作業

---

## 概要

このリポジトリは「めざましリレー」PWA の MVP 実装です。目的は「メール不要で即参加できる低摩擦な起床リレー体験」を提供すること。設計上は "local-first" をデフォルトにしています。

キー設計要点:
- Local-first: Firebase 等のクラウドを必須にせず、localStorage ベースでまず動くように実装。
- オプションで Firebase（Auth/Firestore）へ切替可能（環境変数 `VITE_USE_FIREBASE=1`）。
- PWA: service worker によるキャッシュとオフライン表示をサポート。
- UX: Apple風の UI、スケルトン、トースト、コンフェティ、短い効果音など細かなフィードバックを実装。

## アーキテクチャ概要

- フロントエンド: Vite + React (TypeScript)
- 状態管理: React Hooks + 小さなコンテキスト（Auth, Sound, Toast）
- データ層: `services/firestore.ts` が外側 API を提供し、内部で `localStore`（localStorage）または Firebase 実装に切替
- 認証: `LocalAuthProvider`（localStorage）と `AuthProvider`（Firebase）の切替
- ビルドと CI: Vite build、GitHub Actions で build + smoke test。Netlify へのデプロイ用ワークフローあり。

## 主要ファイルとコンポーネント

（パスは `src/` 下）

- `main.tsx` — アプリエントリ。Auth の選択（local or firebase）と PWA service worker 登録を行う。
- `App.tsx` — ルートコンポーネント。ログイン状態に応じてページを切替え、Onboarding モーダルの起動を管理。

Pages:
- `pages/Dashboard.tsx` — ダッシュボード。今日のセッション、短縮起動フロー、DataManager 呼び出しを含む。
- `pages/Missions.tsx` — ミッション CRUD とステップ一覧。読み込み時は Skeleton を表示。
- `pages/Groups.tsx` — グループ作成／参加、グループの読み込みと統計表示。読み込み時は Skeleton を表示。
- `pages/Sessions.tsx` — セッションの一覧と操作（complete など）。

Components:
- `components/Header.tsx` — ヘッダー、表示名、サウンド切替、OfflineIndicator と InstallPrompt を組み込む。
- `components/OfflineIndicator.tsx` — ネットワーク状態を監視して表示するバッジ。
- `components/InstallPrompt.tsx` — beforeinstallprompt を補足しユーザーへカスタム A2HS バナーを表示。
- `components/Skeleton.tsx` — リスト用のプレースホルダ（shimmer）。
- `components/StepItem.tsx` — セッションのステップ表示。完了すると confetti・振動・短い成功音を鳴らす。
- `components/NameModal.tsx`, `OnboardingModal.tsx` — ユーザー名編集／初回説明用モーダル。
- `components/DataManager.tsx` — エクスポート/インポート、サンプルデータ注入、QR 共有、移行補助の UI。
- `components/Toast.tsx` / `Confetti.tsx` — ユーティリティ UI。

Services:
- `services/localAuth.tsx` — localStorage を使った軽量認証（匿名ユーザーの保存、表示名保存、サインアウト）。
- `services/auth.tsx` — Firebase Auth 用プロバイダ（オプション）。`useAuth()` は環境に応じて localAuth をフォールバック。
- `services/localStore.ts` — localStorage のラッパー。missions, mission_steps, groups, sessions 等の CRUD とバックアップ/エクスポート/インポートを提供。
- `services/firestore.ts` — 公開 API。内部で `USE_FIREBASE` フラグにより Firebase 実装 or localStore 実装をエクスポートする。
- `services/migrate.ts` — `migrateLocalToCloud(userId)` を提供。localStore の一部を Firestore に移行する補助関数（Firebase 有効時に使用）。
- `services/soundProvider.tsx` — WebAudio を用いた短い効果音（click/success）管理。

その他:
- `scripts/smoke.js` — `dist` の存在、`index.html` に `id="root"` が含まれるか、`dist/assets` にアセットがあるかを確認する簡易スモークテスト。
- `package.json` — プロジェクトスクリプト（dev/build/preview/smoke）と依存。
- `.github/workflows/ci.yml` — build + smoke の CI。デバッグ出力を一時追加して問題の調査をサポートする仕組みあり。
- `.github/workflows/deploy-netlify.yml` — 手動デプロイ（workflow_dispatch）。
- `.github/workflows/deploy-netlify-auto.yml` — main push 自動デプロイ（ただし secrets がない場合はスキップする安全策あり）。

## サービス層の詳細

### 認証
- `LocalAuthProvider`:
  - 保存先: `localStorage`（キーは `mz_local_user` など）
  - API: `user`, `signInAnonymously()`, `signOut()`, `setName(name)` などの軽量メソッド。
- `AuthProvider` (Firebase)
  - Firebase Auth を使った匿名ログイン / email-link（後でアカウント化）をサポート。
  - 環境変数 `VITE_USE_FIREBASE=1` を有効にすると Firebase 実装を優先して使用します。

### データストア
- `localStore`:
  - キー: `mz_store_missions`, `mz_store_mission_steps`, `mz_store_groups`, `mz_store_sessions`, `mz_store_session_steps` (など)
  - 主要 API:
    - createMission(userId, data)
    - listMissions(userId)
    - createMissionStep(missionId, step)
    - listMissionSteps(missionId)
    - createGroup(userId, name, mode)
    - joinGroup(userId, groupId)
    - startSession(userId, missionId)
    - finishSession(sessionId)
    - listTodaySessionsByGroup(groupId)
    - completeSessionStep(sessionStepId)
    - exportAll()/importAll(json)
    - saveBackup()/getLatestBackup()

  - 設計方針: Firestore 互換の最小 API を模し、後で Firestore 実装へ差し替え/移行が容易なようにしてある。

### サウンド
- `soundProvider` は WebAudio を直接使って `playClick()` / `playSuccess()` を提供。`SoundProvider` によってミュート状態は `localStorage` に保存される。

## データモデル（代表的な shape）
以下は実装上で使われる主要オブジェクトの概念的な形です（実際のフィールドは `localStore` と `firestore` を参照してください）。

- Mission:
  - id: string
  - user_id: string
  - name: string
  - wake_time: string ("HH:MM")
  - repeat_rule?: string

- MissionStep:
  - id: string
  - mission_id: string
  - label: string
  - order: number
  - type: 'manual' | 'ble' | 'nfc' | ...

- Group:
  - id: string
  - name: string
  - mode: 'RACE' | 'ALL'
  - members: array of user ids (or membership objects)

- Session:
  - id: string
  - group_id?: string
  - user_id: string
  - date: string (YYYY-MM-DD)
  - status: 'started' | 'completed'
  - finished_at?: timestamp

- SessionStep:
  - id: string
  - session_id: string
  - step_id: string (mission_step id)
  - result: 'pending' | 'success' | 'fail'

## PWA とオフライン動作
- `main.tsx` は service worker (`/src/sw.js`) を登録します（`navigator.serviceWorker.register('/src/sw.js')`）。これによりオフラインでの表示やプリキャッシュが可能です。
- `InstallPrompt` コンポーネントでカスタム A2HS（Add to Home Screen）バナーを提供しています。

注意: Service worker の具体的なキャッシュ戦略（プリキャッシュ / ランタイムキャッシュ の実装詳細）は `src/sw.js` を参照してください（必要に応じて調整可能）。

## CI / CD

- `ci.yml`:
  - トリガ: push / pull_request に対して build + smoke を実行
  - スモークテスト: `scripts/smoke.js` による最小検証（dist存在, index に #root があるか, assetsがあるか）
  - デバッグ用の一時ステップ（node/npm バージョン、ls、verbose npm ci など）を設けてトラブルシュート可能にしている。

- `deploy-netlify.yml` (manual) と `deploy-netlify-auto.yml` (auto):
  - manual: Actions UI で任意に実行
  - auto: main push トリガ（secrets がなければデプロイをスキップ）

## ローカル実行とビルド検証

推奨の手順（Windows PowerShell の例）:

```powershell
npm ci
npm run dev    # 開発サーバー
# あるいは
npm run build   # プロダクションビルド -> dist が生成される
npm run smoke   # dist の存在や index の root をチェック
```

ビルド結果の簡易検証: `npm run smoke` が `SMOKE OK — built assets present, index contains root` を出力すれば最小要件は満たしています。

## デプロイ（Netlify）

オプション:

- 手動 (推奨初期運用): GitHub Actions の `Deploy to Netlify (manual)` を UI から実行。あるいはローカルで Netlify CLI を使う:

```powershell
$env:NETLIFY_AUTH_TOKEN = 'your-token'
npx netlify deploy --dir=dist --prod --site=YOUR_SITE_ID
```

- 自動: `deploy-netlify-auto.yml` を有効化（Secrets `NETLIFY_AUTH_TOKEN` と `NETLIFY_SITE_ID` を設定）。push to main で自動的にデプロイされる。ただし運用上はタグベースでの自動化を推奨。

## ローカル→クラウド移行の流れ

1. Firebase プロジェクトを作成し、Auth と Firestore を有効化する。
2. 環境変数をセット:
   - `VITE_USE_FIREBASE=1`
   - `VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_AUTH_DOMAIN`, ... の Firebase 設定を `.env` に追加（Vite の env プレフィックス規則に従う）。
3. `firestore.ts` の Firebase 実装が有効になる。
4. `services/migrate.ts` の `migrateLocalToCloud(userId)` を使い、ローカルデータを Firestore に移行する（ユーザーがアカウント化したとき等に呼び出すのが想定）。

注意: Cloud 移行時は Firestore のセキュリティルールや Cloud Functions による検証・レート制限を導入してください。

## セキュリティと運用上の注意

- local-first モードは非常に使いやすいが、公開サービスとして運用する場合は次を実施してください:
  - クラウドに移行してユーザー認証を導入（メールリンク、OAuth 等）
  - Firestore セキュリティルールで書き込み検証（userId が一致するか等）
  - Cloud Functions で重要な処理をサーバ側で検証（移行、共有、QR の大データ処理など）
  - 不正利用防止のためのレート制限（Cloudflare / Cloud Functions 等）

## よくあるトラブルと対処法

- ビルドで `dist` が出ない: まずローカルで `npm run build` を実行してエラーを確認。Vite のエラーはコード・依存関係・環境変数不足が多い。
- CI の `Invalid workflow file` エラー: YAML 構文や `secrets` 参照の場所（job レベル vs step レベル）に注意。今回もワークフローを分離して解決している。
- デプロイで Netlify が認証エラーを返す: `NETLIFY_AUTH_TOKEN` が正しいか、`NETLIFY_SITE_ID` が正しいかを確認。

## 今後の推奨作業（優先度順）

1. (高) Firestore へ移行する場合はセキュリティルールを先に設計する。最小限の読み書きルールを決める。  
2. (中) E2E テスト (Playwright) を CI に導入し、主要 UX フローを自動検証する。  
3. (中) Netlify 自動デプロイはタグベースに変更して、意図的なリリース操作でのみ本番へ反映する運用を採用する。  
4. (低) QR 共有の大容量対応（アップロード→短縮 URL を生成するサーバサイド）を作る。

---

付録: 変更履歴（実装で加えた主要な変更）
- `LocalAuthProvider` / `localStore` を実装して local-first をデフォルトに切替。  
- オンボーディング、表示名モーダル、DataManager（エクスポート/インポート/AutoBackup/ShareModal）を追加。  
- CI ワークフローにスモークテストとデバッグ出力を追加。  
- Netlify 用に手動 & 自動ワークフローを追加（自動ワークフローは secrets がなければスキップ）。

もしこのドキュメントに追記してほしい項目（API の完全な関数シグネチャ、ファイル内のより詳しいコード断片、FireStore ルールのテンプレートなど）があれば教えてください。必要なら該当ファイルを読み込み、関数一覧や型定義を自動生成してドキュメントに埋めます。

Generated: 2025-11-18
