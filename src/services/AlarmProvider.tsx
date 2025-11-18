/**
 * AlarmProvider - アラーム音（天国と地獄）の管理
 * セッション開始時にループ再生を開始し、全ステップ完了時に停止
 */

import React, { createContext, useContext, useRef, useState, useCallback, useEffect } from 'react';

interface AlarmContextValue {
  isPlaying: boolean;
  startAlarm: () => void;
  stopAlarm: () => void;
  volume: number;
  setVolume: (v: number) => void;
}

const AlarmContext = createContext<AlarmContextValue | null>(null);

export function AlarmProvider({ children }: { children: React.ReactNode }) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [volume, setVolume] = useState(() => {
    try {
      const stored = localStorage.getItem('mz_alarm_volume');
      return stored ? parseFloat(stored) : 0.7;
    } catch {
      return 0.7;
    }
  });

  // 初期化: Audio要素を作成（天国と地獄の音源）
  useEffect(() => {
    const audio = new Audio('/alarm.mp3');
    audio.loop = true;
    audio.volume = volume;
    audioRef.current = audio;

    return () => {
      audio.pause();
      audio.src = '';
    };
  }, []);

  // ボリューム変更
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume;
    }
    try {
      localStorage.setItem('mz_alarm_volume', volume.toString());
    } catch {}
  }, [volume]);

  const startAlarm = useCallback(() => {
    if (!audioRef.current) return;
    
    // ユーザーインタラクションが必要な場合のエラーハンドリング
    audioRef.current.play().then(() => {
      setIsPlaying(true);
      console.log('[Alarm] Started playing heaven-and-hell');
    }).catch((err) => {
      console.error('[Alarm] Failed to play:', err);
      // ユーザーに再生許可を求める（ブラウザのポリシー）
      alert('アラームを再生するには、画面をタップしてください');
    });
  }, []);

  const stopAlarm = useCallback(() => {
    if (!audioRef.current) return;
    
    audioRef.current.pause();
    audioRef.current.currentTime = 0;
    setIsPlaying(false);
    console.log('[Alarm] Stopped');
  }, []);

  const value: AlarmContextValue = {
    isPlaying,
    startAlarm,
    stopAlarm,
    volume,
    setVolume,
  };

  return <AlarmContext.Provider value={value}>{children}</AlarmContext.Provider>;
}

export function useAlarm() {
  const ctx = useContext(AlarmContext);
  if (!ctx) {
    throw new Error('useAlarm must be used within AlarmProvider');
  }
  return ctx;
}
