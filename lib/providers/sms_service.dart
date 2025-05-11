import 'package:flutter/services.dart';

class SmsService {

static const platform = MethodChannel('com.yourdomain.sms_sender');

static Future<void> sendSMS(String number, String message, {Function(bool success, String message)? onResult}) async {
  try {
    final result = await platform.invokeMethod('sendSMS', {
      'number': number,
      'message': message,
    });
    print('Result: $result');
    if (onResult != null) {
      onResult(true, "SMS sent successfully");
    }
  } on PlatformException catch (e) {
    print("Failed to send SMS: '${e.message}'.");
    if (onResult != null) {
      onResult(false, "Failed to send SMS: ${e.message}");
    }
  }
}

}
