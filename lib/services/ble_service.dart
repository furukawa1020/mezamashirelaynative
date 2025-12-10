import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// BLEモーションイベンチE
class BLEMotionEvent {
  final String tagId;
  final String eventType; // OPEN, LIFT, SHAKE, CLOSE, FALSE
  final double confidence;
  final int durationMs;
  final DateTime timestamp;

  BLEMotionEvent({
    required this.tagId,
    required this.eventType,
    required this.confidence,
    required this.durationMs,
    required this.timestamp,
  });

  factory BLEMotionEvent.fromJson(Map<String, dynamic> json) {
    return BLEMotionEvent(
      tagId: json['tag_id'] as String,
      eventType: json['event_type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      durationMs: json['duration_ms'] as int,
      timestamp: DateTime.now(),
    );
  }
}

// BLEサービス�E�EIAO ESP32C3 + MPU6050連携�E�E
class BLEService {
  static const String serviceUuid = '0000180f-0000-1000-8000-00805f9b34fb';
  static const String characteristicUuid =
      '00002a19-0000-1000-8000-00805f9b34fb';

  final _eventController = StreamController<BLEMotionEvent>.broadcast();
  Stream<BLEMotionEvent> get eventStream => _eventController.stream;

  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  final List<BluetoothDevice> _connectedDevices = [];
  bool _isScanning = false;

  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  Future<bool> isAvailable() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return false;

      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      print('BLE availability check error: $e');
      return false;
    }
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isScanning) return;

    try {
      _isScanning = true;

      FlutterBluePlus.scanResults.listen((results) {
        final filteredResults =
            results.where((r) {
              final name = r.device.platformName;
              return name.toLowerCase().contains('xiao') ||
                  name.toLowerCase().contains('mezamashi');
            }).toList();

        _scanResultsController.add(filteredResults);
      });

      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print('Scan start error: $e');
      _isScanning = false;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
    } catch (e) {
      print('Scan stop error: $e');
    }
  }

  Future<bool> connectDevice(BluetoothDevice device) async {
    try {
      if (_connectedDevices.contains(device)) {
        return true;
      }

      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      final services = await device.discoverServices();

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            serviceUuid.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                characteristicUuid.toLowerCase()) {
              await characteristic.setNotifyValue(true);

              characteristic.lastValueStream.listen((value) {
                _handleBLEData(device, value);
              });
            }
          }
        }
      }

      _connectedDevices.add(device);
      return true;
    } catch (e) {
      print('Connect error: $e');
      return false;
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      _connectedDevices.remove(device);
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  Future<void> disconnectAll() async {
    for (var device in List.from(_connectedDevices)) {
      await disconnectDevice(device);
    }
  }

  void _handleBLEData(BluetoothDevice device, List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final event = BLEMotionEvent.fromJson(jsonData);
      _eventController.add(event);
    } catch (e) {
      print('BLE data parse error: $e');
    }
  }

  List<BluetoothDevice> get connectedDevices =>
      List.unmodifiable(_connectedDevices);

  void dispose() {
    disconnectAll();
    _eventController.close();
    _scanResultsController.close();
  }
}
