import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceModel {
  final BluetoothDevice device;
  final String name;
  final String id;
  bool isConnected;
  int rssi; // Signal strength

  DeviceModel({
    required this.device,
    required this.name,
    required this.id,
    this.isConnected = false,
    this.rssi = 0,
  });

  // Helper to check if this is specifically your team's hardware
  bool get isYourStartupDevice => name.contains("ESP32") || name.contains("NavDevice");
}