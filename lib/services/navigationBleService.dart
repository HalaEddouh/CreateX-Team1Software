import 'package:flutter/material.dart';
import 'ble_service.dart';
import 'navigationService.dart';


class NavigationBLEService {
  final BLEService _bleService = BLEService();

  /// Connects to the selected device and navigates if successful
  Future<void> connectAndNavigate(BuildContext context, String routeName) async {
    final device = _bleService.selectedDevice;
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No device selected")),
      );
      return;
    }

    bool connected = await _bleService.connectToDevice(device);

    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device connected")),
      );
      navigationService.navigateWithProcessing(routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to connect")),
      );
    }
  }
}