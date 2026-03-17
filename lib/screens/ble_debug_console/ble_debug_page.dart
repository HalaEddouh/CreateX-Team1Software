import 'package:flutter/material.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  // Placeholder status
  String bleStatus = "Disconnected";

  void _sendInstruction(String command) {
    // This is where you'll call your ble_service.dart later
    print("Sending to ESP32: $command");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Sent: $command")),
    );
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
                leading: const Icon(Icons.bluetooth),
                title: Text("Status: $bleStatus"),
                trailing: ElevatedButton(
                  onPressed: () { /* Add Scan logic */ },
                  child: const Text("Connect"),
                ),
              ),
            ),
            const Spacer(),
            const Text("Manual Controls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _sendInstruction("Vibration_1"),

              
              child: const Text("Vibration 1"),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _sendInstruction("Vibration_2"),
    
              child: const Text("Vibration 2"),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _sendInstruction("Stop"),
            
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text("Stop"),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}