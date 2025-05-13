import 'package:resq.ai/widgets/common/alert_dailog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorHandler {
  static Future<Position> getCurrentLocation(BuildContext context) async {
    try {

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        kAlertDialog(context: context, title: 'Location Permission Denied', message: 'Please enable location permission in your device settings');
        throw Exception('Location permission denied');
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }
}