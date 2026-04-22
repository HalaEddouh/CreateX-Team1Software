import 'package:flutter/material.dart';
import 'screens/route_selection/route_page.dart';
import 'screens/ble_debug_console/ble_debug_page.dart';
import 'screens/apple_watch/apple_watch_page.dart';
import 'screens/route_selection/testing_page.dart';
import 'services/navigationService.dart';
import 'screens/route_selection/apple_watch_joint_route_page.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      navigatorKey: navigationService.navKey,

      // start here
      initialRoute: '/',

      routes: {
        '/': (context) => const HomePage(),
        '/ble': (context) => const DebugPage(),
        '/navigation': (context) => const RoutePage(),
        '/apple-watch': (context) => const AppleWatchPage(),
        '/joint-navigation': (context) => const AppleWatchJointRoutePage(),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutePage()),
                );              },
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              child: const Text("Maze Navigation Page"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TestingPage()),
                );              },
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              child: const Text("Connect to Apple Watch"),
              onPressed: () {
                Navigator.pushNamed(context, '/apple-watch');
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              child: const Text("Apple Watch Joint Navigation"),
              onPressed: () {
                Navigator.pushNamed(context, '/joint-navigation');
              },
            ),
          ],
        ),
      ),
    );
  }
}