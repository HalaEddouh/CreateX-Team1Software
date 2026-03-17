import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  // Singleton pattern: ensures one connection across all screens
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  // Nordic UART Service (NUS) UUIDs
  static const String nusServiceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String nusTxUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // Write
  static const String nusRxUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // Notify

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? selectedDevice;
  BluetoothCharacteristic? _txCharacteristic;

  //store device after scanning
  void setSelectedDevice(BluetoothDevice device) {
    selectedDevice = device;
  }

  // --- 1. SCANNING ---
  
  /// Starts scanning for devices. 
  /// In your UI, you can filter this list by 'LRA-BLE'
  Future<void> startScan() async {
    // Only start if not already scanning
    if (FlutterBluePlus.isScanningNow == false) {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withKeywords: ["LRA-BLE"], // Optional: filters for your device name
      );
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // --- 2. CONNECTION ---

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == nusServiceUuid) {
          for (var char in service.characteristics) {
            
            // App writes to TX to send commands to Arduino
            if (char.uuid.toString().toLowerCase() == nusTxUuid) {
              _txCharacteristic = char;
            }
            
            // App listens to RX to receive "Played effect..." messages
            if (char.uuid.toString().toLowerCase() == nusRxUuid) {
              await char.setNotifyValue(true);
              char.onValueReceived.listen((value) {
                String response = utf8.decode(value);
                print("Device Log: $response");
              });
            }
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

  /// Sends a string command to the Arduino.
  /// Automatically appends '\n' so your processCommand() triggers instantly.
  Future<void> sendCommand(String command) async {
    if (_txCharacteristic == null) {
      print("Error: No TX Characteristic. Is the device connected?");
      return;
    }

    try {
      // utf8.encode converts string to the List<int> BLE requires
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