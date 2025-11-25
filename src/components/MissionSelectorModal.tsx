import React, { useEffect, useState } from 'react';
import { Modal } from './Modal';
import Skeleton from './Skeleton';
import { IconAlarm } from './Icons';
import { listMissions, listMissionSteps } from '../services/localStore';

interface MissionSelectorModalProps {
    open: boolean;
    onClose: () => void;
    onSelect: (missionId: string) => void;
    user: any;
}

interface MissionWithSteps {
    id: string;
    name: string;
    wake_time: string;
    stepCount: number;
}

export function MissionSelectorModal({ open, onClose, onSelect, user }: MissionSelectorModalProps) {
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
        <Modal open={open} onClose={onClose} title="バトンを受け取る">
            <div
                style={{
                    padding: '16px 24px 24px',
                    // iOS safe area support
                    paddingBottom: 'max(24px, env(safe-area-inset-bottom))',
                    background: 'linear-gradient(180deg, #FFFFFF 0%, #F2F2F7 100%)',
                    minHeight: '100%',
                }}
            >
                {loading ? (
                    <div>
                        <Skeleton lines={3} />
                    </div>
                ) : missions.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: '40px 20px', color: '#666' }}>
                        <div style={{ fontSize: 64, marginBottom: 16 }}>👟</div>
                        <p style={{ margin: '0 0 8px 0', fontSize: 18, fontWeight: 700, color: '#1d1d1f' }}>
                            コースが空っぽです！
                        </p>
                        <p style={{ margin: 0, fontSize: 14, color: '#86868b' }}>
                            まずは「ミッション」タブで<br />新しいコース（ミッション）を作りましょう。
                        </p>
                    </div>
                ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                        <div style={{
                            fontSize: 13,
                            fontWeight: 600,
                            color: '#FF9500',
                            textTransform: 'uppercase',
                            letterSpacing: '0.05em',
                            marginBottom: -8,
                            paddingLeft: 4
                        }}>
                            Choose Your Course
                        </div>
                        {missions.map((mission, index) => (
                            <MissionCard
                                key={mission.id}
                                mission={mission}
                                index={index}
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
    index,
    onSelect
}: {
    mission: MissionWithSteps;
    index: number;
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

    // Sports day colors
    const laneColors = ['#FF9500', '#34C759', '#007AFF', '#AF52DE', '#FF2D55'];
    const accentColor = laneColors[index % laneColors.length];

    return (
        <div
            role="button"
            tabIndex={0}
            aria-label={`${mission.name}を選択`}
            style={{
                background: '#FFFFFF',
                borderRadius: 16,
                padding: '20px',
                cursor: 'pointer',
                transition: 'transform 0.1s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.1s',
                transform: isPressed ? 'scale(0.98)' : 'scale(1)',
                boxShadow: isPressed
                    ? '0 2px 8px rgba(0,0,0,0.05)'
                    : '0 8px 24px rgba(0,0,0,0.08)',
                borderLeft: `6px solid ${accentColor}`,
                position: 'relative',
                overflow: 'hidden',
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
            {/* Track Lane Number Background */}
            <div style={{
                position: 'absolute',
                right: -10,
                bottom: -20,
                fontSize: 120,
                fontWeight: 900,
                color: '#F2F2F7',
                zIndex: 0,
                fontFamily: 'Impact, sans-serif',
                opacity: 0.5,
                pointerEvents: 'none',
            }}>
                {index + 1}
            </div>

            <div style={{ position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16 }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                    <div
                        style={{
                            fontSize: 20,
                            fontWeight: 700,
                            color: '#1d1d1f',
                            marginBottom: 6,
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
                            gap: 12,
                            fontSize: 15,
                            color: '#666',
                            flexWrap: 'wrap',
                            alignItems: 'center'
                        }}
                    >
                        <span style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 4,
                            background: '#F2F2F7',
                            padding: '4px 8px',
                            borderRadius: 6,
                            fontWeight: 500
                        }}>
                            <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                                <IconAlarm size={14} /> {mission.wake_time}
                            </span>
                        </span>
                        <span style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 4,
                            fontWeight: 500,
                            color: '#86868b'
                        }}>
                            👟 {mission.stepCount} Steps
                        </span>
                    </div>
                </div>
                <div
                    style={{
                        width: 44,
                        height: 44,
                        minWidth: 44,
                        borderRadius: '50%',
                        background: accentColor,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'white',
                        fontSize: 20,
                        flexShrink: 0,
                        boxShadow: `0 4px 12px ${accentColor}66`,
                    }}
                >
                    ▶
                </div>
            </div>
        </div>
    );
}
