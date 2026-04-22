import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppleWatchPage extends StatefulWidget {
  const AppleWatchPage({super.key});

  @override
  State<AppleWatchPage> createState() => _AppleWatchPageState();
}

class _AppleWatchPageState extends State<AppleWatchPage> {
  static const platform = MethodChannel('com.example.haptic_running/watch');

  Future<void> _sendCommand(String command) async {
    try {
      final String result = await platform.invokeMethod('sendHaptic', {'command': command});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  final List<String> _hapticCommands = [
    'turn-left',
    'turn-right',
    'approaching',
    'arrived',
    'notification',
    'directionUp',
    'directionDown',
    'success',
    'failure',
    'retry',
    'start',
    'stop',
    'click',
    'navigationGenericManeuver',
    'navigationLeftTurn',
    'navigationRightTurn',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apple Watch Connect'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Apple Watch Haptic Tester',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Make sure your Apple Watch is paired, the companion app is running, and test the haptic commands below:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ..._hapticCommands.map<Widget>((command) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: () => _sendCommand(command),
                  child: Text('Send "$command"'),
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }
}