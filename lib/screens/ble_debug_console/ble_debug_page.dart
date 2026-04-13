import 'package:flutter/material.dart';

import '../../services/ble_service.dart';
import '../../widgets/ble_connection_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Debug Console")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const BLEConnectionWidget(),
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