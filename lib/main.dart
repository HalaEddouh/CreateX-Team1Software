import 'package:flutter/material.dart';
import 'screens/route_selection/route_page.dart';
import 'screens/ble_debug_console/ble_debug_page.dart';
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

      // Define your routes here for easy navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const RoutePage(),
        '/debug': (context) => const DebugPage(),
      },
    );
  }
}