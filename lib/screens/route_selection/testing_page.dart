import 'package:flutter/material.dart';
import '../../services/ble_service.dart';
import '../../widgets/ble_connection_widget.dart';

class TestingPage extends StatefulWidget {
  const TestingPage({super.key});

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  final BLEService _bleService = BLEService();

  void _sendCommand(String command) {
    if (_bleService.isConnected) {
      _bleService.sendCommand(command);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent command: $command'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not connected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Pulse Tester'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BLEConnectionWidget(),
            const SizedBox(height: 24),
            const Text(
              'Send Pulse Commands',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _sendCommand('a10'),
              child: const Text('Send "a10" (Low)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _sendCommand('a30'),
              child: const Text('Send "a30" (Medium)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _sendCommand('a127'),
              child: const Text('Send "a127" (High)'),
            ),
          ],
        ),
      ),
    );
  }
}