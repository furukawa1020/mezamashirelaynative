# Firestore スキーマ（雛形）

このファイルは前掲の要件定義に基づく Firestore のコレクション例です。実装時は用途に合わせて最適化してください。

collections:
- users (docId = uid)
  - email
  - name
  - icon_url
  - created_at

- groups (docId = groupId)
  - name
  - mode: "RACE" | "ALL"
  - owner_id
  - created_at

- group_members (docId = `${groupId}_${userId}`)
  - group_id
  - user_id
  - joined_at

- missions (docId = missionId)
  - user_id
  - group_id (nullable)
  - name
  - wake_time
  - repeat_rule
  - created_at

- mission_steps (subcollection under missions or top-level)
  - id
  - mission_id
  - order
  - label
  - type: "manual" | "nfc" | "ble_motion"
  - nfc_tag_id
  - ble_event_type

- sessions (docId = sessionId)
  - user_id
  - group_id
  - mission_id
  - date
  - status
  - started_at
  - finished_at
  - total_ms
  - rank

- session_steps (subcollection under sessions)
  - mission_step_id
  - started_at
  - finished_at
  - result
  - lap_ms

- group_daily_status
  - group_id
  - date
  - all_cleared
  - cleared_members
  - last_clear_member
  - clear_streak

