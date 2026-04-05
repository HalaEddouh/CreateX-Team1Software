import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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

  Future<LatLng?> _geocode(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=AIzaSyCP7Hb7dvscejg9VlO2tTrmN5E8S3vlJx0';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final loc = data['results'][0]['geometry']['location'];
      return LatLng(loc['lat'], loc['lng']);
    }
    return null;
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
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      final newPos = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentLocation = newPos;
      });

      _checkStepProgress(newPos);

      _controller?.animateCamera(
        CameraUpdate.newLatLng(newPos),
      );
    });
  }

  void _checkStepProgress(LatLng userLocation) {
    if (_directions.isEmpty) return;

    final routePoints = _polylines.isNotEmpty
        ? _polylines.first.points
        : <LatLng>[];

    if (_currentStepIndex >= routePoints.length) return;

    final target = routePoints[_currentStepIndex];

    final distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      target.latitude,
      target.longitude,
    );

    if (distance < 15) {
      _currentStepIndex++;

      if (_currentStepIndex < _directions.length) {
        setState(() {
          _nextInstruction = _directions[_currentStepIndex];
        });
      } else {
        setState(() {
          _nextInstruction = "You have arrived 🎉";
        });
      }
    }
  }

  Future<void> _getRoute() async {
    final start = _startController.text;
    final end = _endController.text;

    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter both locations")),
      );
      return;
    }

    final startLatLng = await _geocode(start);
    final endLatLng = await _geocode(end);

    if (startLatLng == null || endLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not find one of the locations")),
      );
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${startLatLng.latitude},${startLatLng.longitude}'
        '&destination=${endLatLng.latitude},${endLatLng.longitude}'
        '&mode=walking'
        '&key=AIzaSyCP7Hb7dvscejg9VlO2tTrmN5E8S3vlJx0';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] != 'OK' ||
        data['routes'] == null ||
        data['routes'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Directions failed: ${data['status']}")),
      );
      return;
    }

    final encoded = data['routes'][0]['overview_polyline']['points'];
    final routePoints = _decodePolyline(encoded);

    final steps = data['routes'][0]['legs'][0]['steps'];
    _directions = [];

    for (var step in steps) {
      final instruction = step['html_instructions']
          .replaceAll(RegExp(r'<[^>]*>'), '');
      final distance = step['distance']['text'];
      _directions.add("$instruction ($distance)");
    }

    setState(() {
      _markers.clear();
      _polylines.clear();
      _currentStepIndex = 0;
      _nextInstruction = _directions.isNotEmpty ? _directions[0] : "";

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
        points: routePoints,
        width: 5,
        color: Colors.blue,
      ));
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(startLatLng, 14),
    );

    _startLiveTracking();
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Route Planner")),

      body: Column(
        children: [
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

          // MAP
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

          // DIRECTIONS LIST
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