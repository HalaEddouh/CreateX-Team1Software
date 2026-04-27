import 'dart:async';
import '../../services/ble_service.dart';
import '../../services/route_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../widgets/ble_connection_widget.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  GoogleMapController? _controller;

  final TextEditingController _endController = TextEditingController();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  List<NavigationStep> _navigationSteps = [];

  final BLEService _bleService = BLEService();

  final RouteService _routeService = RouteService();

  StreamSubscription<Position>? _positionStream;

  LatLng? _currentLocation;

  int _currentStepIndex = 0;

  String _nextInstruction = "";

  String _activeCommand = "";

  int distanceToStep = 0;

  Timer? _commandTimer;

  bool _isCommandSent = false;

  static const CameraPosition _initialPosition =
      CameraPosition(target: LatLng(33.7490, -84.3880), zoom: 12);

  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _endController.dispose();
    _positionStream?.cancel();
    _commandTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLiveTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position pos) {
      final newPos = LatLng(pos.latitude, pos.longitude);

      _checkStepProgress(newPos);

      _controller?.animateCamera(
        CameraUpdate.newLatLng(newPos),
      );
    });

    // Run _sendCommand periodically, e.g., every 1 second.
    _commandTimer?.cancel();
    _commandTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _sendCommand();
    });
  }

  void _checkStepProgress(LatLng userLocation) {
    if (_navigationSteps.isEmpty ||
        _currentStepIndex >= _navigationSteps.length) {
      return;
    }

    final currentStep = _navigationSteps[_currentStepIndex];
    final targetLocation = currentStep.location;

    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      targetLocation.latitude,
      targetLocation.longitude,
    );

    distanceToStep = distance.toInt();

    // Debug prints to reveal the coordinate mismatch
    print("Device Location: ${userLocation.latitude}, ${userLocation.longitude}");
    print("Route Target: ${targetLocation.latitude}, ${targetLocation.longitude}");

    String commandToSend;

    // 1. Find the maneuver for the UPCOMING intersection (which is the next step's maneuver)
    String upcomingManeuver;
    if (_currentStepIndex + 1 < _navigationSteps.length) {
      upcomingManeuver = _navigationSteps[_currentStepIndex + 1].maneuver;
    } else {
      upcomingManeuver = 'arrived';
    }

    // Determine command based on maneuver and distance
    if (distance < 15) {
      // Closest
      commandToSend = 'a127';
    } else if (distance < 25) {
      // Closesr
      commandToSend = 'a30';
    } else if (distance < 50) {
      // Approaching
      commandToSend = 'a10';
    } else {
      commandToSend = '0';
    }

    setState(() {
      _activeCommand = commandToSend;
    });


    // Logic to advance to the next step
    if (distance < 15) {
      // Threshold to move to next instruction (must be less than the 25m threshold above)
      _currentStepIndex++;
      if (_currentStepIndex < _navigationSteps.length) {
        setState(() {
          // 2. UI logic: Show the user what is coming up next
          if (_currentStepIndex + 1 < _navigationSteps.length) {
            _nextInstruction = "Next: ${_navigationSteps[_currentStepIndex + 1].instruction}";
          } else {
            _nextInstruction = "Next: Arrive at destination";
          }
        });
      } else {
        setState(() {
          _nextInstruction = "You have arrived 🎉";
        });
        _commandTimer?.cancel();
      }
    }
  }

  Future<void> _sendCommand() async {
        // Send the command via BLE
    if (_activeCommand.isNotEmpty && _bleService.isConnected) {
      _bleService.sendCommand(_activeCommand);
      
      setState(() {
        _isCommandSent = true;
      });
      // Briefly flash the icon green for 300 milliseconds
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isCommandSent = false);
        }
      });
    }
  }

  Future<void> _getRoute() async {
    final end = _endController.text;

    if (end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a destination")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission is required to calculate the route")),
      );
      return;
    }

    setState(() {
      _hasLocationPermission = true;
    });

    final currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final startLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);
    final endLatLng = await _routeService.geocode(end);

    if (endLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not find the destination location")),
      );
      return;
    }

    final routeDetails = await _routeService.getRoute(startLatLng, endLatLng);

    if (routeDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not get directions")),
      );
      return;
    }

    _navigationSteps = routeDetails.navigationSteps;

    setState(() {
      _markers.clear();
      _polylines.clear();
      _currentStepIndex = 0;
      _activeCommand = "";
      _nextInstruction = _navigationSteps.length > 1
          ? "Next: ${_navigationSteps[1].instruction}"
          : (_navigationSteps.isNotEmpty ? _navigationSteps[0].instruction : "");

      _markers.add(Marker(
        markerId: const MarkerId("start"),
        position: startLatLng,
      ));

      _markers.add(Marker(
        markerId: const MarkerId("end"),
        position: endLatLng,
      ));

      _polylines.add(Polyline(
        polylineId: const PolylineId("route"),
        points: routeDetails.polylinePoints,
        width: 5,
        color: Colors.blue,
      ));
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(startLatLng, 14),
    );

    _startLiveTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Route Planner")),

      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: BLEConnectionWidget(),
          ),
          // 🔔 LIVE INSTRUCTION BAR
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

          // INPUT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    labelText: "Destination",
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

          // MAP
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (c) => _controller = c,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: _hasLocationPermission,
                ),
                // 🛠 BLE COMMAND DEBUG WIDGET
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeCommand.isNotEmpty ? Colors.orange : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bluetooth_audio, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "BLE Command: ${_activeCommand.isEmpty ? 'None' : _activeCommand} | Distance: ${distanceToStep}m",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.circle,
                          size: 14,
                          color: _isCommandSent ? Colors.greenAccent : Colors.white30,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // DIRECTIONS LIST
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: _navigationSteps.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Text("${index + 1}"),
                  title: Text(_navigationSteps[index].instruction),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}