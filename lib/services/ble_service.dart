import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  // Singleton pattern
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? selectedDevice;
  BluetoothCharacteristic? _txCharacteristic;

  // Set the device selected from scan
  void setSelectedDevice(BluetoothDevice device) {
    selectedDevice = device;
  }

  // --- 1. SCANNING ---
  Future<void> startScan() async {
    if (!FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withKeywords: ["LRA-BLE"],
      );
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // --- 2. CONNECTION ---
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          // TX characteristic (write)
          if (char.uuid.toString().toLowerCase() ==
              "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
            _txCharacteristic = char;
          }
          // RX characteristic (notify)
          if (char.uuid.toString().toLowerCase() ==
              "6e400003-b5a3-f393-e0a9-e50e24dcca9e") {
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
              String response = utf8.decode(value);
              print("Device Log: $response");
            });
          }
        }
      }
      return true;
    } catch (e) {
      print("Connection Error: $e");
      return false;
    }
  }

  // --- 3. COMMUNICATION ---
  Future<void> sendCommand(String command) async {
    if (_txCharacteristic == null) {
      print("Error: No TX Characteristic. Device not connected?");
      return;
    }
    try {
      await _txCharacteristic!.write(
        utf8.encode("$command\n"),
        withoutResponse: false,
      );
      print("Sent command: $command");
    } catch (e) {
      print("Write Error: $e");
    }
  }

  // --- 4. DISCONNECT ---
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _txCharacteristic = null;
  }

  bool get isConnected => _connectedDevice != null && _txCharacteristic != null;
}