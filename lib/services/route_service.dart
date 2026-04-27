import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class NavigationStep {
  final String instruction;
  final LatLng location;
  final String maneuver;

  NavigationStep({
    required this.instruction,
    required this.location,
    required this.maneuver,
  });
}

class RouteDetails {
  final List<LatLng> polylinePoints;
  final List<NavigationStep> navigationSteps;

  RouteDetails({required this.polylinePoints, required this.navigationSteps});
}

class RouteService {
  static const String _apiKey = "AIzaSyCP7Hb7dvscejg9VlO2tTrmN5E8S3vlJx0";

  Future<LatLng?> geocode(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        final loc = data['results'][0]['geometry']['location'];
        return LatLng(loc['lat'], loc['lng']);
      }
    }
    return null;
  }

  Future<RouteDetails?> getRoute(LatLng start, LatLng end) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${start.latitude},${start.longitude}'
        '&destination=${end.latitude},${end.longitude}'
        '&mode=walking'
        '&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);

    if (data['status'] != 'OK' ||
        data['routes'] == null ||
        data['routes'].isEmpty) {
      print("Directions API Error: ${data['status']} - ${data['error_message']}");
      return null;
    }

    final route = data['routes'][0];
    final encodedPolyline = route['overview_polyline']['points'];
    final routePoints = _decodePolyline(encodedPolyline);

    final leg = route['legs'][0];
    final stepsData = leg['steps'];

    List<NavigationStep> navigationSteps = [];
    for (var step in stepsData) {
      final instruction =
          step['html_instructions'].replaceAll(RegExp(r'<[^>]*>'), '');
      final location = step['end_location'];
      final maneuver = step['maneuver'] ?? 'straight';

      navigationSteps.add(NavigationStep(
        instruction: instruction,
        location: LatLng(location['lat'], location['lng']),
        maneuver: maneuver,
      ));
    }

    return RouteDetails(
      polylinePoints: routePoints,
      navigationSteps: navigationSteps,
    );
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
}