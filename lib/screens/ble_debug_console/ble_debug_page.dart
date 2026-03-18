import 'package:flutter/material.dart';
import '../../services/ble_service.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String bleStatus = "Disconnected";

  // List of required button values
  final List<String> commands = [
    "1", "2", "3", "4", "5", "sweep", "stop", "help", "e50"
  ];

  void _sendInstruction(String command) {
    if (BLEService().isConnected) {
      BLEService().sendCommand(command);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sent: $command"), duration: const Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connect device first.")),
      );
    }
  }

  Future<void> _handleConnect() async {
    final device = BLEService().selectedDevice;

    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No device selected")),
      );
      return;
    }

    bool connected = await BLEService().connectToDevice(device);
    setState(() {
      bleStatus = connected ? "Connected" : "Disconnected";
    });

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to connect")),
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
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.bluetooth,
                  color: bleStatus == "Connected" ? Colors.blue : Colors.grey,
                ),
                title: Text("Status: $bleStatus"),
                trailing: ElevatedButton(
                  onPressed: _handleConnect,
                  child: const Text("Connect"),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Manual Controls",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Wrap allows buttons to flow to the next line automatically
            Wrap(
              spacing: 12, // horizontal gap
              runSpacing: 12, // vertical gap
              alignment: WrapAlignment.center,
              children: commands.map((cmd) {
                return SizedBox(
                  width: 100, // Fixed width for a uniform grid look
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cmd == "stop" ? Colors.red.shade400 : null,
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