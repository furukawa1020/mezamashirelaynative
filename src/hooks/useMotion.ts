import { useState, useEffect } from 'react';

export function useMotion(threshold = 15) {
    const [acceleration, setAcceleration] = useState({ x: 0, y: 0, z: 0 });
    const [shakeCount, setShakeCount] = useState(0);
    const [isShaking, setIsShaking] = useState(false);

    useEffect(() => {
        let lastX = 0, lastY = 0, lastZ = 0;
        let lastUpdate = 0;

        const handleMotion = (event: DeviceMotionEvent) => {
            const current = event.accelerationIncludingGravity;
            if (!current) return;

            const { x, y, z } = current;
            const curTime = Date.now();

            if ((curTime - lastUpdate) > 100) {
                const diffTime = curTime - lastUpdate;
                lastUpdate = curTime;

                const speed = Math.abs((x || 0) + (y || 0) + (z || 0) - lastX - lastY - lastZ) / diffTime * 10000;

                if (speed > threshold * 100) { // Adjust sensitivity
                    setShakeCount(prev => prev + 1);
                    setIsShaking(true);
                    setTimeout(() => setIsShaking(false), 500);
                }

                lastX = x || 0;
                lastY = y || 0;
                lastZ = z || 0;
                setAcceleration({ x: lastX, y: lastY, z: lastZ });
            }
        };

        // Request permission for iOS 13+
        const requestPermission = async () => {
            if (typeof (DeviceMotionEvent as any).requestPermission === 'function') {
                try {
                    const response = await (DeviceMotionEvent as any).requestPermission();
                    if (response === 'granted') {
                        window.addEventListener('devicemotion', handleMotion);
                    }
                } catch (e) {
                    console.error(e);
                }
            } else {
                window.addEventListener('devicemotion', handleMotion);
            }
        };

        requestPermission();

        return () => {
            window.removeEventListener('devicemotion', handleMotion);
        };
    }, [threshold]);

    return { acceleration, shakeCount, isShaking, resetCount: () => setShakeCount(0) };
}
