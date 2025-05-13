import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

Future<List<LatLng>> fetchRouteFromORS(LatLng start, LatLng end) async {
  final apiKey = '5b3ce3597851110001cf6248388fe4b378014bc989e60ead2735c31f';
  
  // Format coordinates with proper precision
  final startCoord = '${start.longitude.toStringAsFixed(6)},${start.latitude.toStringAsFixed(6)}';
  final endCoord = '${end.longitude.toStringAsFixed(6)},${end.latitude.toStringAsFixed(6)}';
  
  final url = Uri.parse(
    'https://api.openrouteservice.org/v2/directions/driving-car'
  ).replace(queryParameters: {
    'api_key': apiKey,
    'start': startCoord,
    'end': endCoord,
  });

  try {
    print('Fetching route from: $startCoord to $endCoord');
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/geo+json;charset=UTF-8',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      
      if (decoded['features'] == null || decoded['features'].isEmpty) {
        throw Exception('No route found between the specified points');
      }

      final coords = decoded['features'][0]['geometry']['coordinates'] as List;
      // Convert the coordinates to LatLng list
      final List<LatLng> points = [];
      for (var coord in coords) {
        // OpenRouteService returns coordinates in [longitude, latitude] format
        points.add(LatLng(coord[1] as double, coord[0] as double));
      }
      return points;
    } else {
      print('Route API Error Response: ${response.body}');
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  } catch (e) {
    print('Route Fetch Error: $e');
    rethrow;
  }
}
