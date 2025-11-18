/**
 * めざましリレー BLE センサ — XIAO ESP32C3 + MPU6050
 * 
 * 機能:
 * - MPU6050 から 100Hz で加速度・ジャイロを取得
 * - モーションパターン検出（OPEN / LIFT / SHAKE / CLOSE / FALSE）
 * - シーケンス検出（OPEN → LIFT → CLOSE）
 * - BLE GATT Service で JSON イベントを Notify
 * 
 * 配線:
 *   MPU6050 SDA → XIAO D4 (GPIO6)
 *   MPU6050 SCL → XIAO D5 (GPIO7)
 *   MPU6050 VCC → 3.3V
 *   MPU6050 GND → GND
 * 
 * Arduino IDE 設定:
 *   ボード: "XIAO_ESP32C3"
 *   ライブラリ: Adafruit MPU6050, Adafruit Sensor, BLE (ESP32 標準)
 */

#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>

// ========== 設定 ==========
#define DEVICE_NAME "MezamashiTag_01"
#define TAG_ID "device_01"

// BLE UUID (カスタム)
#define SERVICE_UUID        "0000180f-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_UUID "00002a19-0000-1000-8000-00805f9b34fb"

// I2C ピン (XIAO ESP32C3)
#define SDA_PIN 6  // D4
#define SCL_PIN 7  // D5

// サンプリング間隔
#define SAMPLE_RATE_HZ 100
#define SAMPLE_INTERVAL_MS (1000 / SAMPLE_RATE_HZ)

// しきい値
#define ANGLE_THRESHOLD 30.0       // 角度変化しきい値（度）
#define ACCEL_PEAK_THRESHOLD 2.5   // 加速度ピークしきい値（g）
#define FALSE_SPEED_THRESHOLD 3.0  // やったフリ速度しきい値（g）
#define SETTLE_TIME_MS 500         // 静止判定時間（ms）
#define SEQUENCE_TIMEOUT_MS 2000   // シーケンスタイムアウト（ms）

// ========== グローバル変数 ==========
Adafruit_MPU6050 mpu;
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

// センサデータ
struct IMUData {
  float ax, ay, az;  // 加速度（g）
  float gx, gy, gz;  // ジャイロ（deg/s）
  float pitch, roll; // 推定角度（度）
  unsigned long ts;  // タイムスタンプ（ms）
};

IMUData currentData;
IMUData baselineData;  // 初期姿勢

// モーションイベント
enum MotionEvent {
  NONE,
  OPEN,
  LIFT,
  SHAKE,
  CLOSE,
  FALSE_MOTION
};

// シーケンス状態
enum SequenceState {
  IDLE,
  OPEN_STATE,
  LIFT_STATE,
  CLOSE_STATE
};

SequenceState sequenceState = IDLE;
unsigned long sequenceStartTime = 0;
unsigned long lastEventTime = 0;

// ========== BLE コールバック ==========
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("BLE: Client connected");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("BLE: Client disconnected");
    // 再アドバタイズ
    BLEDevice::startAdvertising();
  }
};

// ========== セットアップ ==========
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Mezamashi Relay BLE Sensor ===");

  // I2C 初期化
  Wire.begin(SDA_PIN, SCL_PIN);
  
  // MPU6050 初期化
  if (!mpu.begin()) {
    Serial.println("ERROR: MPU6050 not found!");
    while (1) delay(10);
  }
  Serial.println("MPU6050 initialized");

  // MPU6050 設定
  mpu.setAccelerometerRange(MPU6050_RANGE_4_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  // ベースライン取得（初期姿勢）
  delay(500);
  readIMU(&baselineData);
  Serial.printf("Baseline: pitch=%.1f roll=%.1f\n", 
                baselineData.pitch, baselineData.roll);

  // BLE 初期化
  setupBLE();

  Serial.println("Setup complete. Waiting for BLE connection...");
}

// ========== BLE セットアップ ==========
void setupBLE() {
  BLEDevice::init(DEVICE_NAME);
  
  // BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // BLE Service
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // BLE Characteristic (Notify)
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->addDescriptor(new BLE2902());

  // サービス開始
  pService->start();

  // アドバタイズ開始
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE: Advertising started");
}

// ========== メインループ ==========
void loop() {
  static unsigned long lastSampleTime = 0;
  unsigned long now = millis();

  // 100Hz サンプリング
  if (now - lastSampleTime >= SAMPLE_INTERVAL_MS) {
    lastSampleTime = now;
    
    // IMU 読み取り
    readIMU(&currentData);

    // モーション検出
    MotionEvent event = detectMotion(&currentData, &baselineData);

    // シーケンス処理
    if (event != NONE) {
      processSequence(event, now);
    }

    // タイムアウトチェック
    if (sequenceState != IDLE && (now - lastEventTime > SEQUENCE_TIMEOUT_MS)) {
      Serial.println("Sequence timeout, resetting to IDLE");
      sequenceState = IDLE;
    }
  }

  // 接続が切れたら再アドバタイズ
  if (!deviceConnected) {
    delay(500);
  }
}

// ========== IMU データ読み取り ==========
void readIMU(IMUData* data) {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  data->ax = a.acceleration.x / 9.81;  // g に変換
  data->ay = a.acceleration.y / 9.81;
  data->az = a.acceleration.z / 9.81;
  data->gx = g.gyro.x * 180.0 / PI;    // deg/s に変換
  data->gy = g.gyro.y * 180.0 / PI;
  data->gz = g.gyro.z * 180.0 / PI;
  data->ts = millis();

  // 簡易的な角度推定（加速度ベース）
  data->pitch = atan2(data->ay, sqrt(data->ax * data->ax + data->az * data->az)) * 180.0 / PI;
  data->roll = atan2(-data->ax, data->az) * 180.0 / PI;
}

// ========== モーション検出 ==========
MotionEvent detectMotion(IMUData* current, IMUData* baseline) {
  // 角度変化
  float pitchDelta = abs(current->pitch - baseline->pitch);
  float rollDelta = abs(current->roll - baseline->roll);
  float angleDelta = max(pitchDelta, rollDelta);

  // 加速度ノルム
  float accelNorm = sqrt(current->ax * current->ax + 
                         current->ay * current->ay + 
                         current->az * current->az);

  // 速度（簡易）
  float speed = sqrt(current->gx * current->gx + 
                     current->gy * current->gy + 
                     current->gz * current->gz);

  // デバッグ出力
  static unsigned long lastDebugTime = 0;
  if (millis() - lastDebugTime > 1000) {
    Serial.printf("angle=%.1f accel=%.2fg speed=%.1fdeg/s\n", 
                  angleDelta, accelNorm, speed);
    lastDebugTime = millis();
  }

  // やったフリ検出（高速→即静止）
  static float lastSpeed = 0;
  static unsigned long lastHighSpeedTime = 0;
  if (speed > FALSE_SPEED_THRESHOLD) {
    lastHighSpeedTime = millis();
  }
  if (lastSpeed > FALSE_SPEED_THRESHOLD && speed < 10 && 
      (millis() - lastHighSpeedTime < 100)) {
    lastSpeed = speed;
    return FALSE_MOTION;
  }
  lastSpeed = speed;

  // OPEN（扉を開ける）
  if (angleDelta > ANGLE_THRESHOLD && accelNorm < ACCEL_PEAK_THRESHOLD) {
    delay(SETTLE_TIME_MS);  // 静止確認
    return OPEN;
  }

  // LIFT（持ち上げ）
  if (current->az > 1.2 && angleDelta > 20) {
    delay(300);  // 持ち上げ保持確認
    return LIFT;
  }

  // CLOSE（元の角度に戻る）
  if (angleDelta < 10 && sequenceState == LIFT_STATE) {
    return CLOSE;
  }

  // SHAKE（軽く振る）
  static float accelHistory[10] = {0};
  static int historyIndex = 0;
  accelHistory[historyIndex] = accelNorm;
  historyIndex = (historyIndex + 1) % 10;
  
  float accelStd = 0;
  float accelMean = 0;
  for (int i = 0; i < 10; i++) accelMean += accelHistory[i];
  accelMean /= 10;
  for (int i = 0; i < 10; i++) accelStd += pow(accelHistory[i] - accelMean, 2);
  accelStd = sqrt(accelStd / 10);
  
  if (accelStd > 0.3) {
    return SHAKE;
  }

  return NONE;
}

// ========== シーケンス処理 ==========
void processSequence(MotionEvent event, unsigned long now) {
  Serial.printf("Event: %s (state=%d)\n", eventToString(event), sequenceState);

  lastEventTime = now;

  switch (sequenceState) {
    case IDLE:
      if (event == OPEN) {
        sequenceState = OPEN_STATE;
        sequenceStartTime = now;
        Serial.println("Sequence: OPEN detected");
      } else {
        // 単発イベントとして送信
        sendBLEEvent(eventToString(event), 0.8, 0);
      }
      break;

    case OPEN_STATE:
      if (event == LIFT) {
        sequenceState = LIFT_STATE;
        Serial.println("Sequence: LIFT detected");
      } else if (now - sequenceStartTime > SEQUENCE_TIMEOUT_MS) {
        sequenceState = IDLE;
      }
      break;

    case LIFT_STATE:
      if (event == CLOSE) {
        unsigned long duration = now - sequenceStartTime;
        sequenceState = IDLE;
        Serial.println("Sequence: COMPLETE (OPEN->LIFT->CLOSE)");
        sendBLEEvent("OPEN_LIFT_CLOSE", 0.95, duration);
      } else if (now - sequenceStartTime > SEQUENCE_TIMEOUT_MS) {
        sequenceState = IDLE;
      }
      break;
  }
}

// ========== BLE イベント送信 ==========
void sendBLEEvent(const char* eventType, float confidence, unsigned long durationMs) {
  if (!deviceConnected) {
    Serial.println("BLE: Not connected, skipping notify");
    return;
  }

  // JSON 生成
  StaticJsonDocument<256> doc;
  doc["tag_id"] = TAG_ID;
  doc["event"] = eventType;
  doc["confidence"] = confidence;
  doc["ts"] = millis() / 1000;  // Unix timestamp (秒)
  if (durationMs > 0) {
    doc["duration_ms"] = durationMs;
  }

  String jsonString;
  serializeJson(doc, jsonString);

  // BLE Notify
  pCharacteristic->setValue(jsonString.c_str());
  pCharacteristic->notify();

  Serial.printf("BLE Notify: %s\n", jsonString.c_str());
}

// ========== ヘルパー関数 ==========
const char* eventToString(MotionEvent event) {
  switch (event) {
    case OPEN: return "OPEN";
    case LIFT: return "LIFT";
    case SHAKE: return "SHAKE";
    case CLOSE: return "CLOSE";
    case FALSE_MOTION: return "FALSE";
    default: return "NONE";
  }
}
