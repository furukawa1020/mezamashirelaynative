import { useState, useEffect, useCallback, useMemo } from 'react';

export function useGeolocation() {
    const [location, setLocation] = useState<GeolocationCoordinates | null>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (!navigator.geolocation) {
            setError('Geolocation is not supported by your browser');
            return;
        }

        const id = navigator.geolocation.watchPosition(
            (position) => {
                setLocation(position.coords);
                setError(null);
            },
            (err) => {
                setError(err.message);
            },
            {
                enableHighAccuracy: true,
                timeout: 5000,
                maximumAge: 0
            }
        );

        return () => navigator.geolocation.clearWatch(id);
    }, []);

    // Calculate distance in meters between two coordinates (Haversine formula)
    const getDistanceFrom = useCallback((lat: number, lng: number) => {
        if (!location) return null;
        const R = 6371e3; // metres
        const φ1 = location.latitude * Math.PI / 180;
        const φ2 = lat * Math.PI / 180;
        const Δφ = (lat - location.latitude) * Math.PI / 180;
        const Δλ = (lng - location.longitude) * Math.PI / 180;

        const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }, [location]);

    return useMemo(() => ({ location, error, getDistanceFrom }), [location, error, getDistanceFrom]);
}
