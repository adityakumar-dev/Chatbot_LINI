import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await Geolocator.requestPermission();
    await Geolocator.isLocationServiceEnabled();

    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_updates',
      'Location Updates',
      description: 'This channel is used for location tracking notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> startLocationService(String userId) async {
    developer.log('Location Service: Starting with user_id: $userId', name: 'LocationService');

    await initialize();

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: false,
        notificationChannelId: 'location_updates',
        initialNotificationTitle: 'Rescue.AI',
        initialNotificationContent: 'Location update service is running...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: (_) async => true,
      ),
    );

    await _service.startService();

    // Give some time to ensure the isolate starts before sending userId
    await Future.delayed(const Duration(seconds: 1));

    _service.invoke('setUserId', {'user_id': userId});
  }

  static Future<void> stopLocationService() async {
    _service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  String? userId;

  service.invoke('updateNotification', {
    'title': 'Rescue.AI',
    'content': 'Waiting for user ID...',
  });

  service.on('setUserId').listen((event) {
    userId = event?['user_id']?.toString();
    if (userId != null) {
      developer.log('User ID received in isolate: $userId', name: 'LocationService');
      _startLocationLoop(service, userId!);
    }
  });

  // Timeout if no user ID is received within 30 seconds
  Future.delayed(Duration(seconds: 30), () {
    if (userId == null) {
      developer.log('User ID not received, stopping service', name: 'LocationService');
      service.stopSelf();
    }
  });
}

void _startLocationLoop(ServiceInstance service, String userId) {
  Timer? locationTimer;
  int updateCount = 0;

  _updateLocation(service, userId, updateCount);

  locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    updateCount++;
    _updateLocation(service, userId, updateCount);
  });

  service.on('stopService').listen((_) {
    locationTimer?.cancel();
    service.stopSelf();
  });
}

void _updateLocation(ServiceInstance service, String userId, int updateCount) async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final locationString = '${position.latitude},${position.longitude}';

    // Update notification with more detailed information
    service.invoke('updateNotification', {
      'title': 'Rescue.AI Active',
      'content': 'Location Update #$updateCount\n$locationString',
      'subText': 'Last updated: ${DateTime.now().toString().substring(11, 19)}',
    });

    final response = await http.post(
      Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/user/update/location'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'location': locationString,
      }),
    );

    developer.log('Location sent: $locationString | Response: ${response.statusCode}', name: 'LocationService');
  } catch (e) {
    developer.log('Failed to update location: $e', name: 'LocationService');
    // Update notification with error
    service.invoke('updateNotification', {
      'title': 'Rescue.AI Error',
      'content': 'Failed to update location\nTap to retry',
      'subText': 'Last error: ${DateTime.now().toString().substring(11, 19)}',
    });
  }
}
