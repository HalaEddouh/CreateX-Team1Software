import 'package:flutter/material.dart';
import 'ble_service.dart'; // keep this

class NavigationService {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  final BLEService bleService = BLEService(); // ← add this

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  void goBack() {
    navKey.currentState?.pop();
  }

  Future<dynamic>? navigateWithProcessing(String routeName, {Object? arguments}) {
    if (bleService.isConnected) { // ← use this instead of ble_service()
      print("BLE is connected.");
      return navKey.currentState?.pushNamed(routeName, arguments: arguments);
    } else {
      print("BLE is not connected.");
      ScaffoldMessenger.of(navKey.currentContext!).showSnackBar(
        const SnackBar(content: Text("Connect device."))
      );
      return null;
    }
  }
}

final navigationService = NavigationService(); // ← keep this