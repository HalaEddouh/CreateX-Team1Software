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
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        // 🎨 Global color system
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // modern blue
          brightness: Brightness.light,
        ),

        // 🌫 App background
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),

        // 🧭 AppBar styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      navigatorKey: navigationService.navKey,

      initialRoute: '/',

      routes: {
        '/': (context) => const HomePage(),
        '/ble': (context) => const DebugPage(),
        '/navigation': (context) => const RoutePage(),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ble');
                  },
                  child: const Text("BLE Debug Console"),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/navigation');
                  },
                  child: const Text("Start Navigation"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}