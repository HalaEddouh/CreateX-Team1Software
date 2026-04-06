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

  final List<String> commands = [
    "1", "2", "3", "4", "5", "sweep", "stop", "help", "e50"
  ];

  @override
  void initState() {
    super.initState();
    // Listen to value notifiers to rebuild the widget on change
    _bleService.selectedDeviceNotifier.addListener(_rebuild);
    _bleService.connectionStatusNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    _bleService.selectedDeviceNotifier.removeListener(_rebuild);
    _bleService.connectionStatusNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    setState(() {});
  }

  void _sendInstruction(String command) {
    if (_bleService.isConnected) {
      _bleService.sendCommand(command);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sent: $command"),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device is not connected.")),
      );
    }
  }

  Future<void> _handleConnect() async {
    if (_bleService.selectedDeviceNotifier.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No device selected. Please scan first.")),
      );
      return;
    }
    await _bleService.connectToDevice(_bleService.selectedDeviceNotifier.value!);
  }

  Future<void> _handleDisconnect() async {
    await _bleService.disconnect();
  }

  Future<void> _scanForDevices() async {
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    } else if (Platform.isIOS) {
      await Permission.bluetooth.request();
    }

    final adapterState = await _bleService.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth is off. Please enable it to scan.'),
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
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
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

    await FlutterBluePlus.stopScan();
    if (selected != null) {
      _bleService.setSelectedDevice(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = _bleService.selectedDeviceNotifier.value;
    final connectionStatus = _bleService.connectionStatusNotifier.value;

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
                        color: connectionStatus == "Connected"
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      title: Text("Status: $connectionStatus"),
                      subtitle: Text(selectedDevice?.platformName ?? "No device selected"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _scanForDevices,
                          child: const Text("Scan"),
                        ),
                        const SizedBox(width: 8),
                        if (connectionStatus != "Connected")
                          ElevatedButton(
                            onPressed: connectionStatus == "Connecting..."
                                ? null
                                : _handleConnect,
                            child: connectionStatus == "Connecting..."
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text("Connect"),
                          )
                        else
                          ElevatedButton(
                            onPressed: _handleDisconnect,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text("Disconnect"),
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