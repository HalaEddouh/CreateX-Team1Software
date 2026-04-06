import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  // Singleton pattern
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  // Nordic UART Service (NUS) UUIDs
  static const String nusServiceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String nusTxUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // Write
  static const String nusRxUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // Notify

  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _connectionStateSubscription;

  // --- State Notifiers ---
  final ValueNotifier<BluetoothDevice?> selectedDeviceNotifier =
      ValueNotifier(null);
  final ValueNotifier<String> connectionStatusNotifier =
      ValueNotifier("Disconnected");

  void setSelectedDevice(BluetoothDevice device) {
    selectedDeviceNotifier.value = device;
    connectionStatusNotifier.value = "Disconnected";
  }

  // --- 1. SCANNING ---
  Future<void> startScan() async {
    if (FlutterBluePlus.isScanningNow == false) {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  // --- 2. CONNECTION ---
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (isConnected) {
      await disconnect();
    }
    
    connectionStatusNotifier.value = "Connecting...";

    try {
      await device.connect();
      _txCharacteristic = null; 

      _listenToConnectionChanges(device);

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == nusServiceUuid) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == nusTxUuid) {
              _txCharacteristic = char;
            }
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

      if (_txCharacteristic == null) {
        await device.disconnect();
        connectionStatusNotifier.value = "Failed to connect";
        return false;
      }

      connectionStatusNotifier.value = "Connected";
      return true;
    } catch (e) {
      print("Connection Error: $e");
      connectionStatusNotifier.value = "Failed to connect";
      return false;
    }
  }
  
  void _listenToConnectionChanges(BluetoothDevice device) {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        connectionStatusNotifier.value = "Disconnected";
        _txCharacteristic = null;
      }
    });
  }

  // --- 3. COMMUNICATION ---
  Future<void> sendCommand(String command) async {
    if (_txCharacteristic == null) {
      print("Error: No TX Characteristic. Is the device connected?");
      return;
    }
    try {
      await _txCharacteristic!.write(
        utf8.encode(command),
        withoutResponse: false,
      );
      print("Sent command: $command");
    } catch (e) {
      print("Write Error: $e");
    }
  }

  // --- 4. DISCONNECT ---
  Future<void> disconnect() async {
    _connectionStateSubscription?.cancel();
    await selectedDeviceNotifier.value?.disconnect();
    _txCharacteristic = null;
    connectionStatusNotifier.value = "Disconnected";
  }

  bool get isConnected => connectionStatusNotifier.value == "Connected";
}