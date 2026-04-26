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

  bool _isLoading = false;

  int _currentStepIndex = 0;
  String _nextInstruction = "";

  static const CameraPosition _initialPosition =
      CameraPosition(target: LatLng(33.7490, -84.3880), zoom: 12);

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<LatLng?> _geocode(String address) async {
    const apiKey = "AIzaSyAuxdUnmsftr_-W8moT0bvN3GAoyOvbauI";

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final loc = data['results'][0]['geometry']['location'];
      return LatLng(loc['lat'], loc['lng']);
    }
    return null;
  }

  Future<void> _getRoute() async {
    final start = _startController.text.trim();
    final end = _endController.text.trim();

    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter both start and destination")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startLatLng = await _geocode(start);
      final endLatLng = await _geocode(end);

      if (startLatLng == null || endLatLng == null) {
        throw Exception("Could not find locations");
      }

      const apiKey = "AIzaSyAuxdUnmsftr_-W8moT0bvN3GAoyOvbauI";

      final url =
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${startLatLng.latitude},${startLatLng.longitude}'
          '&destination=${endLatLng.latitude},${endLatLng.longitude}'
          '&mode=walking'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] != 'OK') {
        throw Exception("Google API error: ${data['status']}");
      }

      // ✅ FIXED TYPE SAFETY HERE
      final List steps =
          data['routes'][0]['legs'][0]['steps'] as List;

      _directions = steps.map<String>((step) {
        final map = step as Map<String, dynamic>;
        final instruction = map['html_instructions'] as String;
        return instruction.replaceAll(RegExp(r'<[^>]*>'), '');
      }).toList();

      final encoded = data['routes'][0]['overview_polyline']['points'];
      final routePoints = _decodePolyline(encoded);

      setState(() {
        _markers.clear();
        _polylines.clear();
        _currentStepIndex = 0;
        _nextInstruction =
            _directions.isNotEmpty ? _directions[0] : "";

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
          width: 6,
          color: const Color(0xFF2563EB),
        ));
      });

      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(startLatLng, 14),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Route failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        title: const Text("Route Planner"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (c) => _controller = c,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _startController,
                    decoration: const InputDecoration(
                      hintText: "Start location",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _endController,
                    decoration: const InputDecoration(
                      hintText: "Destination",
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _getRoute,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Navigate"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_nextInstruction.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _nextInstruction,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}