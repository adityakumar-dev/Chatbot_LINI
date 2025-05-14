import 'package:chatbot_lini/config/services/location_service.dart';
import 'package:flutter/material.dart';

class LocationCheckerProvider extends ChangeNotifier {
  bool _isLocationServiceRunning = false;

 bool get isLocationServiceRunning => _isLocationServiceRunning;
  
  void updateLocationServiceStatus(bool status) {
    _isLocationServiceRunning = status;
    notifyListeners();
  }
}
