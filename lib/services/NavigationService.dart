import 'package:flutter/material.dart';
import 'ble_service.dart'

class NavigationService {
    
    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

    Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
        return navKey.currentState?.pushNamed(routeName, arguments: arguments);
    }

    void goBack() {
        navKey.currentState?.pop();
    }

    Future<dynamic>? navigateWithProcessing(String routeName, {Object? arguments}) {
        if (ble_service().isConnected){
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

final navigationService = NavigationService();