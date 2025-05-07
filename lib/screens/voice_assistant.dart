import 'dart:convert';
import 'package:flutter/material.dart';
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
  String _userSpeech = '';
  String _responseText = '';
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _requestMicPermission();
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize();
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("You said:", style: TextStyle(color: Colors.white54)),
                    Text(_userSpeech,
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    SizedBox(height: 20),
                    Text("Assistant says:",
                        style: TextStyle(color: Colors.white54)),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _responseText,
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Microphone Button with reliable long press handling
            Listener(
              onPointerDown: (_) {
                _startListening();
              },
              onPointerUp: (_) {
                _stopListening();
              },
              child: Container(
                margin: EdgeInsets.all(20),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white24,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.mic, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
