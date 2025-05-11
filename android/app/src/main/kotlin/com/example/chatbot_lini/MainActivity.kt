package com.example.chatbot_lini

import android.os.Bundle
import android.telephony.SmsManager
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yourdomain.sms_sender"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "sendSMS") {
                    val number = call.argument<String>("number")
                    val message = call.argument<String>("message")

                    Log.d("SMS_DEBUG", "Attempting to send SMS to: $number with message: $message")

                    if (number.isNullOrBlank() || message.isNullOrBlank()) {
                        Log.e("SMS_ERROR", "Number or message is null/blank")
                        result.error("INVALID_ARGUMENTS", "Phone number or message is missing", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager = SmsManager.getDefault()
                        smsManager.sendTextMessage(number, null, message, null, null)

                        Log.d("SMS_DEBUG", "SMS sent successfully to $number")
                        Toast.makeText(applicationContext, "SMS sent to $number", Toast.LENGTH_SHORT).show()
                        result.success("SMS sent")
                    } catch (e: Exception) {
                        Log.e("SMS_ERROR", "Failed to send SMS: ${e.localizedMessage}")
                        Toast.makeText(applicationContext, "Failed to send SMS: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
                        result.error("SEND_FAILED", "Failed to send SMS: ${e.localizedMessage}", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
