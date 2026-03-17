import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  static const CameraPosition _initialPosition =
      CameraPosition(target: LatLng(33.7490, -84.3880), zoom: 12);

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<LatLng?> _geocode(String address) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=AIzaSyAVZeDwKSr2CTDcAd0CzUSAn1vQl5jXkpY';

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geocoding failed: ${data['status']}')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Geocoding error: $e')));
      return null;
    }
  }

  Future<void> _getRoute(String startAddress, String endAddress) async {
    final startLatLng = await _geocode(startAddress);
    final endLatLng = await _geocode(endAddress);

    if (startLatLng == null || endLatLng == null) return;

    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${startLatLng.latitude},${startLatLng.longitude}&destination=${endLatLng.latitude},${endLatLng.longitude}&key=AIzaSyAYE8HOaGP_J4uqZ2xD_9S6yazyMU7NRak';

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0]['overview_polyline']['points'];
        _addPolyline(route);

        setState(() {
          _markers.clear();
          _markers.add(Marker(
            markerId: const MarkerId('start'),
            position: startLatLng,
            infoWindow: InfoWindow(title: startAddress),
          ));
          _markers.add(Marker(
            markerId: const MarkerId('end'),
            position: endLatLng,
            infoWindow: InfoWindow(title: endAddress),
          ));
        });

        _controller?.animateCamera(
          CameraUpdate.newLatLngZoom(startLatLng, 12),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Directions failed: ${data['status']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Directions error: $e')));
    }
  }

  void _addPolyline(String encodedPolyline) {
    List<LatLng> points = _decodePolyline(encodedPolyline);
    setState(() {
      _polylines.clear();
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

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

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Screen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: 'Start Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    labelText: 'End Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  child: const Text('Show Route'),
                  onPressed: () {
                    if (_startController.text.isNotEmpty &&
                        _endController.text.isNotEmpty) {
                      _getRoute(
                          _startController.text, _endController.text);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (controller) => _controller = controller,
              myLocationEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
          ),
        ],
      ),
    );
  }
}