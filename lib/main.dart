import 'package:flutter/material.dart';
import 'screens/route_selection/route_page.dart';
import 'screens/ble_debug_console/ble_debug_page.dart';
import 'screens/navigation_screen.dart';
import 'services/navigationService.dart';

final NavigationService navigationService = NavigationService();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Navigation App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      navigatorKey: navigationService.navKey,

      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/ble': (context) => const DebugPage(), // BLE debug page
        '/navigation': (context) => const NavigationScreen(), // NEW navigation screen
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Go to BLE Debug"),
              onPressed: () {
                Navigator.pushNamed(context, '/ble');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text("Start Navigation"),
              onPressed: () {
                Navigator.pushNamed(context, '/navigation');
              },
            ),
          ],
        ),
      ),
    );
  }
}