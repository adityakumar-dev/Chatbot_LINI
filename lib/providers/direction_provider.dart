import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

Future<List<LatLng>> fetchRouteFromORS(LatLng start, LatLng end) async {
  final apiKey = '5b3ce3597851110001cf6248388fe4b378014bc989e60ead2735c31f';
  final distance = Distance();
  final meters = distance(start, end);

  if (meters > 6000000) {
    throw Exception('Route too long: exceeds 6000 km limit of ORS');
  }

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
      final List<LatLng> points = coords
          .map<LatLng>((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();
      return points;
    } else {
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  } catch (e) {
    print('Route Fetch Error: $e');
    rethrow;
  }
}
