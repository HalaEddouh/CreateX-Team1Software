import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ble_service.dart';
import '../../services/navigationService.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final BLEService _bleService = BLEService();
  BluetoothDevice? _selectedDevice;
  StreamSubscription? _connectionStateSubscription;
  String _bleStatus = "Disconnected";

  final List<String> commands = [
    "1", "2", "3", "4", "5", "sweep", "stop", "help", "e50"
  ];

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _scanForDevices() async {
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    } else if (Platform.isIOS) {
      await [
        Permission.bluetooth,
      ].request();
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Bluetooth is off or permissions denied. Enable to scan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await FlutterBluePlus.stopScan();
    await _bleService.startScan();

    final selected = await showDialog<BluetoothDevice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select a Device"),
          content: StreamBuilder<List<ScanResult>>(
            stream: _bleService.scanResults,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return SizedBox(
                height: 300,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final result = snapshot.data![index];
                    return ListTile(
                      title: Text(result.device.platformName),
                      subtitle: Text(result.device.remoteId.toString()),
                      onTap: () => Navigator.of(context).pop(result.device),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );

    await FlutterBluePlus.stopScan();

    if (selected != null) {
      _bleService.setSelectedDevice(selected);
      setState(() {
        _selectedDevice = selected;
        _bleStatus = "Disconnected";
      });
    }
  }

  Future<void> _handleConnectAndNavigate() async {
    final device = _bleService.selectedDevice;
    if (device == null) return;

    setState(() => _bleStatus = "Connecting...");
    bool connected = await _bleService.connectToDevice(device);

    if (mounted) {
      setState(() {
        _bleStatus = connected ? "Connected" : "Failed to connect";
      });
      if (connected) {
        navigationService.navigateWithProcessing('/navigation');
      }
    }
  }

  void _sendInstruction(String command) {
    if (_bleService.isConnected) {
      _bleService.sendCommand(command);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sent: $command"), duration: const Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device not connected.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Debug Console")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.bluetooth,
                    color: _bleStatus == "Connected" ? Colors.blue : Colors.grey),
                title: Text("Status: $_bleStatus"),
                subtitle: Text(_selectedDevice?.platformName ?? "No device selected"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: _scanForDevices, child: const Text("Scan")),
                    ElevatedButton(
                      onPressed: _handleConnectAndNavigate,
                      child: const Text("Connect & Navigate"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Manual Controls",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: commands.map((cmd) {
                return SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cmd == "stop" ? Colors.red : null,
                      foregroundColor: cmd == "stop" ? Colors.white : null,
                    ),
                    onPressed: () => _sendInstruction(cmd),
                    child: Text(cmd.toUpperCase()),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}