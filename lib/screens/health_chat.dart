import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HealthChatScreen extends StatefulWidget {
  final String userQuery;
  final bool isAccident;

  HealthChatScreen({required this.userQuery, required this.isAccident});

  @override
  _HealthChatScreenState createState() => _HealthChatScreenState();
}

class _HealthChatScreenState extends State<HealthChatScreen> {
  String assistantResponse = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _sendPrompt(widget.userQuery);
  }

  Future<void> _sendPrompt(String prompt) async {
    final uri = Uri.parse(
        'https://enabled-flowing-bedbug.ngrok-free.app/api/${widget.isAccident ?"road-safety" : "health"}?query=${Uri.encodeComponent(prompt)}');

    final request = http.Request("GET", uri);

    try {
      final response = await request.send();

      response.stream
          .transform(utf8.decoder)
          .listen((chunk) {
            final lines = chunk.trim().split(RegExp(r'data: '));
            for (var line in lines) {
              if (line.trim().isEmpty) continue;
              try {
                final data = json.decode(line);
                if (data['content'] != null) {
                  setState(() {
                    assistantResponse += data['content'];
                  });
                }
              } catch (_) {
                // Ignore malformed chunks
              }
            }
          }, onDone: () {
            setState(() => isLoading = false);
          }, onError: (e) {
            setState(() {
              assistantResponse = "⚠️ Failed to get response.";
              isLoading = false;
            });
          });
    } catch (e) {
      setState(() {
        assistantResponse = "❌ Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ResQ.Ai Help"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("You asked:",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text(widget.userQuery, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text("Rescue.AI says:",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  assistantResponse,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 10),
                    Text("Rescue.AI is typing..."),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}