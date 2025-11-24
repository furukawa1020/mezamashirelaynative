import React, { useEffect, useState } from 'react';
import { Modal } from './Modal';
import { listMissions, listMissionSteps } from '../services/localStore';
import { useAuth } from '../services/auth';
import Skeleton from './Skeleton';

interface MissionSelectorModalProps {
    open: boolean;
    onClose: () => void;
    onSelect: (missionId: string) => void;
}

interface MissionWithSteps {
    id: string;
    name: string;
    wake_time: string;
    stepCount: number;
}

export function MissionSelectorModal({ open, onClose, onSelect }: MissionSelectorModalProps) {
    const { user } = useAuth();
    const [missions, setMissions] = useState<MissionWithSteps[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!open || !user) return;

        const loadMissions = async () => {
            setLoading(true);
            try {
                const missionList = await listMissions(user.uid);

                // Load step counts for each mission
                const missionsWithSteps = await Promise.all(
                    missionList.map(async (mission: any) => {
                        const steps = await listMissionSteps(mission.id);
                        return {
                            id: mission.id,
                            name: mission.name,
                            wake_time: mission.wake_time,
                            stepCount: steps.length,
                        };
                    })
                );

                setMissions(missionsWithSteps);
            } catch (error) {
                console.error('Failed to load missions:', error);
            } finally {
                setLoading(false);
            }
        };

        loadMissions();
    }, [open, user]);

    const handleSelect = (missionId: string) => {
        onSelect(missionId);
        onClose();
    };

    return (
        <Modal open={open} onClose={onClose} title="ミッションを選択">
            <div
                style={{
                    padding: '16px 24px 24px',
                    // iOS safe area support
                    paddingBottom: 'max(24px, env(safe-area-inset-bottom))',
                }}
            >
                {loading ? (
                    <div>
                        <Skeleton lines={3} />
                    </div>
                ) : missions.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: '40px 20px', color: '#666' }}>
                        <div style={{ fontSize: 48, marginBottom: 16 }}>📋</div>
                        <p style={{ margin: '0 0 8px 0', fontSize: 16, fontWeight: 600, color: '#1d1d1f' }}>
                            ミッションがありません
                        </p>
                        <p style={{ margin: 0, fontSize: 14, color: '#666' }}>
                            先に「ミッション」タブでミッションを作成してください。
                        </p>
                    </div>
                ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                        {missions.map((mission) => (
                            <MissionCard
                                key={mission.id}
                                mission={mission}
                                onSelect={handleSelect}
                            />
                        ))}
                    </div>
                )}
            </div>
        </Modal>
    );
}

// Separate component for better performance and touch handling
function MissionCard({
    mission,
    onSelect
}: {
    mission: MissionWithSteps;
    onSelect: (id: string) => void;
}) {
    const [isPressed, setIsPressed] = useState(false);

    const handleTouchStart = () => setIsPressed(true);
    const handleTouchEnd = () => setIsPressed(false);
    const handleMouseDown = () => setIsPressed(true);
    const handleMouseUp = () => setIsPressed(false);
    const handleMouseLeave = () => setIsPressed(false);

    const handleClick = () => {
        onSelect(mission.id);
    };

    return (
        <div
            role="button"
            tabIndex={0}
            aria-label={`${mission.name}を選択`}
            style={{
                background: isPressed ? '#e8e8ea' : '#f5f5f7',
                borderRadius: 12,
                padding: 16,
                cursor: 'pointer',
                transition: 'all 0.15s ease',
                border: isPressed ? '2px solid #007aff' : '2px solid transparent',
                // Prevent text selection on touch devices
                WebkitUserSelect: 'none',
                userSelect: 'none',
                // Disable tap highlight on mobile
                WebkitTapHighlightColor: 'transparent',
                // Improve touch responsiveness
                touchAction: 'manipulation',
            }}
            onTouchStart={handleTouchStart}
            onTouchEnd={handleTouchEnd}
            onMouseDown={handleMouseDown}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseLeave}
            onClick={handleClick}
            onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    handleClick();
                }
            }}
        >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                    <div
                        style={{
                            fontSize: 18,
                            fontWeight: 600,
                            color: '#1d1d1f',
                            marginBottom: 4,
                            // Prevent text overflow on small screens
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                        }}
                    >
                        {mission.name}
                    </div>
                    <div
                        style={{
                            display: 'flex',
                            gap: 16,
                            fontSize: 14,
                            color: '#666',
                            flexWrap: 'wrap',
                        }}
                    >
                        <span style={{ whiteSpace: 'nowrap' }}>⏰ {mission.wake_time}</span>
                        <span style={{ whiteSpace: 'nowrap' }}>📝 {mission.stepCount} ステップ</span>
                    </div>
                </div>
                <div
                    style={{
                        width: 32,
                        height: 32,
                        minWidth: 32,
                        borderRadius: '50%',
                        background: '#007aff',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'white',
                        fontSize: 18,
                        flexShrink: 0,
                    }}
                >
                    →
                </div>
            </div>
        </div>
    );
}
