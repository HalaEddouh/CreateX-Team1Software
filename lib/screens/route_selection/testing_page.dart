import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ble_service.dart';
import '../../widgets/ble_connection_widget.dart';

class TestingPage extends StatefulWidget {
  const TestingPage({super.key});

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  final BLEService _bleService = BLEService();

  static const platform = MethodChannel('com.example.hapticRunning/watch');

  final List<String> _hapticCommands = [
    'notification',
    'directionUp',
    'directionDown',
    'success',
    'failure',
    'retry',
    'start',
    'stop',
    'click'
  ];

  Future<void> _sendWatchCommand(String command) async {
    try {
      final String result = await platform.invokeMethod('sendHaptic', {'command': command});
      if (mounted && result != 'Command queued for when watch wakes up') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

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
      body: SingleChildScrollView(
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
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _sendCommand('sweep'),
              child: const Text('Send "sweep"'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _sendCommand('stop'),
              child: const Text('Send "stop" (0)'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Apple Watch Haptics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ..._hapticCommands.map<Widget>((command) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: () => _sendWatchCommand(command),
                    child: Text('Send "$command"'),
                  ),
                )).toList(),
          ],
        ),
      ),
    );
  }
}