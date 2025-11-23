import React, { useEffect, useRef, useState } from 'react';
import { Html5QrcodeScanner } from 'html5-qrcode';

interface QRScannerProps {
    onScan: (decodedText: string) => void;
    fps?: number;
    qrbox?: number;
}

export default function QRScanner({ onScan, fps = 10, qrbox = 250 }: QRScannerProps) {
    const [error, setError] = useState<string | null>(null);
    const scannerRef = useRef<Html5QrcodeScanner | null>(null);

    useEffect(() => {
        // Prevent multiple initializations
        if (scannerRef.current) return;

        try {
            const scanner = new Html5QrcodeScanner(
                "reader",
                { fps, qrbox },
        /* verbose= */ false
            );

            scanner.render(
                (decodedText) => {
                    onScan(decodedText);
                    // Optional: Stop scanning after success if needed, but usually parent handles unmount
                },
                (errorMessage) => {
                    // parse error, ignore mostly
                }
            );

            scannerRef.current = scanner;
        } catch (e: any) {
            setError(e.message);
        }

        return () => {
            if (scannerRef.current) {
                scannerRef.current.clear().catch(console.error);
                scannerRef.current = null;
            }
        };
    }, [onScan, fps, qrbox]);

    return (
        <div style={{ width: '100%', maxWidth: 400, margin: '0 auto' }}>
            {error && <div style={{ color: 'red', marginBottom: 8 }}>Camera Error: {error}</div>}
            <div id="reader"></div>
        </div>
    );
}
