import React, { useEffect, useRef, useState } from 'react';
import Webcam from 'react-webcam';
import * as cocoSsd from '@tensorflow-models/coco-ssd';
import '@tensorflow/tfjs';

interface AICameraProps {
    targetLabel: string;
    onDetected: () => void;
}

export default function AICamera({ targetLabel, onDetected }: AICameraProps) {
    const webcamRef = useRef<Webcam>(null);
    const [model, setModel] = useState<cocoSsd.ObjectDetection | null>(null);
    const [predictions, setPredictions] = useState<cocoSsd.DetectedObject[]>([]);
    const [loading, setLoading] = useState(true);

    // Load model
    useEffect(() => {
        const loadModel = async () => {
            try {
                const loadedModel = await cocoSsd.load();
                setModel(loadedModel);
                setLoading(false);
            } catch (err) {
                console.error('Failed to load model', err);
            }
        };
        loadModel();
    }, []);

    // Detection loop
    useEffect(() => {
        if (!model || !webcamRef.current?.video) return;

        const interval = setInterval(async () => {
            if (webcamRef.current && webcamRef.current.video && webcamRef.current.video.readyState === 4) {
                const video = webcamRef.current.video;
                const preds = await model.detect(video);
                setPredictions(preds);

                // Check for target
                const found = preds.find(p => p.class.toLowerCase() === targetLabel.toLowerCase() && p.score > 0.6);
                if (found) {
                    onDetected();
                }
            }
        }, 500); // Check every 500ms

        return () => clearInterval(interval);
    }, [model, targetLabel, onDetected]);

    return (
        <div style={{ position: 'relative', width: '100%', maxWidth: 400, margin: '0 auto' }}>
            {loading && <div style={{ textAlign: 'center', padding: 20 }}>AIモデル読み込み中...</div>}

            <Webcam
                ref={webcamRef}
                audio={false}
                screenshotFormat="image/jpeg"
                videoConstraints={{ facingMode: 'environment' }}
                style={{ width: '100%', borderRadius: 12 }}
            />

            {/* Bounding Boxes Overlay */}
            <div style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, pointerEvents: 'none' }}>
                {predictions.map((p, i) => (
                    <div key={i} style={{
                        position: 'absolute',
                        left: `${p.bbox[0]}px`, // Note: This mapping depends on video scaling, might need adjustment if video is scaled via CSS
                        top: `${p.bbox[1]}px`,
                        width: `${p.bbox[2]}px`,
                        height: `${p.bbox[3]}px`,
                        border: '2px solid #0a84ff',
                        backgroundColor: 'rgba(10, 132, 255, 0.2)',
                        borderRadius: 4
                    }}>
                        <span style={{ position: 'absolute', top: -20, left: 0, background: '#0a84ff', color: 'white', padding: '2px 4px', fontSize: 12, borderRadius: 4 }}>
                            {p.class} {Math.round(p.score * 100)}%
                        </span>
                    </div>
                ))}
            </div>

            <div style={{ textAlign: 'center', marginTop: 8, color: '#8e8e93', fontSize: 12 }}>
                探しているもの: <strong>{targetLabel}</strong>
            </div>
        </div>
    );
}
