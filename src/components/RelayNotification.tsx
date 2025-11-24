
useEffect(() => {
  if (!user) return;

  const checkRelay = async () => {
    try {
      const backend = localStore;

      // 今日のセッションを取得
      const sessions = await backend.listTodaySessionsByUser(user.uid);
      const completedSession = sessions.find((s: any) => s.status === 'completed' && s.group_id);

      if (!completedSession) return;

      // グループ情報を取得
      const group = await backend.getGroup(completedSession.group_id);
      if (!group || group.mode !== 'RACE') return;

      // グループメンバーを取得
      const members = await backend.listGroupMembers(group.id);
      const memberIds = members.map((m: any) => m.user_id);
      const myIndex = memberIds.indexOf(user.uid);

      if (myIndex === -1) return;

      if (myIndex === memberIds.length - 1) {
        // 最後の人なのでリレー完了
        setRelayStatus('🏆 あなたがラストランナーです！全員完了しました');
        return;
      }

      // 次の人のIDを取得
      const nextUserId = memberIds[myIndex + 1];

      // 全セッションから次の人のセッションをチェック
      const allSessions = await backend.listTodaySessionsByGroup?.(group.id) || sessions;
      const nextUserSessions = allSessions.filter((s: any) => s.user_id === nextUserId);
      const nextUserCompleted = nextUserSessions.some((s: any) => s.status === 'completed');

      if (nextUserCompleted) {
        setRelayStatus('次の走者も完了しています');
      } else {
        setRelayStatus('次の走者にバトンタッチしました！');

        // 通知（Web Push Notification は権限が必要なので、簡易版としてトースト）
        showToast(`次の走者（メンバー ${myIndex + 2}）にバトンタッチ！`);
      }
    } catch (error) {
      console.error('Relay check error:', error);
    }
  };

  checkRelay();

  // 10秒ごとにチェック
  const interval = setInterval(checkRelay, 10000);

  return () => clearInterval(interval);
}, [user, showToast]);

if (!relayStatus) return null;

return (
  <div style={{ padding: 12, background: '#fff3cd', borderRadius: 8, marginBottom: 16, textAlign: 'center' }}>
    <div style={{ fontSize: 14, fontWeight: 500 }}>{relayStatus}</div>
  </div>
);
}
