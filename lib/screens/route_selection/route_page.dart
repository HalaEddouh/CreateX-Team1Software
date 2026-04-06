import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:haptic_running/services/navigationBleService.dart';

final navigationBLEService = NavigationBLEService();

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  GoogleMapController? _controller;

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  List<String> _directions = [];

  StreamSubscription<Position>? _positionStream;

  LatLng? _currentLocation;

  int _currentStepIndex = 0;

  String _nextInstruction = "";

  static const CameraPosition _initialPosition =
      CameraPosition(target: LatLng(33.7490, -84.3880), zoom: 12);

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  // --- BLE Navigation Button ---
  Widget _buildBLEConnectButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          // Connect to selected device and navigate
          navigationBLEService.connectAndNavigate(context, '/navigation');
        },
        child: const Text("Connect BLE Device"),
      ),
    );
  }

  // --- Geocode Address ---
  Future<LatLng?> _geocode(String address) async {
    // Example: implement Google Maps Geocoding API call here
    return null;
  }

  // --- Start Live Tracking ---
  Future<void> _startLiveTracking() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _checkStepProgress(_currentLocation!);
      });
    });
  }

  // --- Check Step Progress ---
  void _checkStepProgress(LatLng userLocation) {
    // Implement your logic for checking progress along route steps
  }

  // --- Get Route ---
  Future<void> _getRoute() async {
    // Implement fetching directions and polyline decoding
    // Example: using _decodePolyline on API polyline data
  }

  // --- Decode Polyline ---
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Route Planner")),
      body: Column(
        children: [
          // BLE Connect Button
          _buildBLEConnectButton(),

          // Live Instruction Bar
          if (_nextInstruction.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black87,
              child: Text(
                _nextInstruction,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

          // Start / End Inputs
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: "Start Location",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    labelText: "End Location",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _getRoute,
                  child: const Text("Get Walking Route"),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (c) => _controller = c,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),

          // Directions List
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: _directions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Text("${index + 1}"),
                  title: Text(_directions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}