import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ble_service.dart';

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

  // List of required button values
  final List<String> commands = [
    "1", "2", "3", "4", "5", "sweep", "stop", "help", "e50"
  ];

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    super.dispose();
  }

  void _sendInstruction(String command) {
    // Check connection status via the property in BLEService
    if (_bleService.isConnected) {
      _bleService.sendCommand(command);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Sent: $command"),
            duration: const Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device is not connected.")),
      );
    }
  }

  Future<void> _handleConnect() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No device selected. Please scan first.")),
      );
      return;
    }

    setState(() {
      _bleStatus = "Connecting...";
    });

    bool connected = await _bleService.connectToDevice(_selectedDevice!);

    if (mounted) {
      setState(() {
        _bleStatus = connected ? "Connected" : "Failed to connect";
      });

      if (connected) {
        // Cancel any previous subscription
        _connectionStateSubscription?.cancel();
        _connectionStateSubscription =
            _selectedDevice!.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected && mounted) {
            setState(() {
              _bleStatus = "Disconnected";
            });
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to connect")),
        );
      }
    }
  }

  Future<void> _scanForDevices() async {
    // Request necessary permissions
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


    // First, check if bluetooth is on
    final adapterState = await _bleService.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth is off or permissions are denied. Please enable it to scan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Stop any active scan before starting a new one
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
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Scanning..."),
                    ],
                  ),
                );
              }
              return SizedBox(
                height: 300,
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final result = snapshot.data![index];
                    // Filtering out unnamed devices
                    if (result.device.platformName.isNotEmpty) {
                      return ListTile(
                        title: Text(result.device.platformName),
                        subtitle: Text(result.device.remoteId.toString()),
                        onTap: () => Navigator.of(context).pop(result.device),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );

    // Stop scanning once dialog is closed
    await FlutterBluePlus.stopScan();

    if (selected != null) {
      _bleService.setSelectedDevice(selected);
      setState(() {
        _selectedDevice = selected;
        // Reset status when a new device is selected
        _bleStatus = "Disconnected";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Debug Console")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.bluetooth,
                        color: _bleStatus == "Connected"
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      title: Text("Status: $_bleStatus"),
                      subtitle: Text(_selectedDevice?.platformName ?? "No device selected"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _scanForDevices,
                          child: const Text("Scan"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _bleStatus == "Connecting..." ? null : _handleConnect,
                          child: _bleStatus == "Connecting..."
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Connect"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Manual Controls",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: commands.map((cmd) {
                return SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          cmd == "stop" ? Colors.red.shade400 : null,
                      foregroundColor: cmd == "stop" ? Colors.white : null,
                    ),
                    onPressed: () => _sendInstruction(cmd),
                    child: Text(cmd.toUpperCase()),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}