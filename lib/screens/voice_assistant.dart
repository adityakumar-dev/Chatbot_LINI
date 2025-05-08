import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class VoiceAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VoiceAssistantPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VoiceAssistantPage extends StatefulWidget {
  @override
  _VoiceAssistantPageState createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage> {
  late stt.SpeechToText _speech;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _userSpeech = '';
  String _responseText = '';
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    await _requestMicPermission();
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize();
  }

  Future<void> _initTts() async {
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required.')),
      );
    }
  }

  void _startListening() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    }

    if (!_speechAvailable) await _initSpeech();
    if (_speechAvailable && !_isListening) {
      setState(() {
        _userSpeech = '';
        _responseText = '';
        _isListening = true;
      });
      await _speech.listen(
        onResult: (val) {
          setState(() => _userSpeech = val.recognizedWords);
        },
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });

      // Wait for the speech-to-text conversion to complete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_userSpeech.isNotEmpty) {
          print("User Speech: $_userSpeech");
          _fetchAndSpeakResponse(_userSpeech);
        } else {
          setState(() {
            _responseText = "I couldn't hear anything. Please try again.";
          });
        }
      });
    }
  }

  void _fetchAndSpeakResponse(String prompt) async {
    final uri = Uri.parse(
        'https://enabled-flowing-bedbug.ngrok-free.app/api/voice?prompt=${Uri.encodeComponent(prompt)}');
    final request = http.Request("POST", uri);

    try {
      final response = await request.send();

      final buffer = StringBuffer();

      response.stream.transform(utf8.decoder).listen(
        (chunk) {
          final lines = chunk.trim().split(RegExp(r'data: '));
          for (var line in lines) {
            if (line.trim().isEmpty) continue;
            try {
              final data = json.decode(line);
              if (data['content'] != null) {
                buffer.write(data['content']);
                setState(() {
                  _responseText = buffer.toString();
                });
              }
            } catch (e) {
              print("SSE parse error: $e");
            }
          }
        },
        onDone: () async {
          // Speak only after full response is accumulated
          final fullResponse = buffer.toString();
          if (fullResponse.isNotEmpty) {
            setState(() {
              _isSpeaking = true;
            });
            await _flutterTts.speak(fullResponse);
          }
        },
        onError: (error) {
          setState(() {
            _responseText = "Error processing response: $error";
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _responseText = "Something went wrong. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black :Colors.blue,
        elevation: 0,
        title: Text(
          'Voice Assistant',
          style: TextStyle(color: !isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [IconButton(onPressed: ()=> context.pop(), icon: Icon(Icons.close,color: Colors.white,))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Speech Section
            Text(
              "You said:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white12 : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _userSpeech.isEmpty ? "..." : _userSpeech,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Assistant Response Section
            Text(
              "Assistant says:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white12 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _responseText.isEmpty ? "..." : _responseText,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) {
          _startListening();
        },
        onTapUp: (_) {
          _stopListening();
        },
        child: Container(
          margin: const EdgeInsets.all(20),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _isListening ? Colors.red : Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.mic,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
