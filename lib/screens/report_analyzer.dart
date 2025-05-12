import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ReportAnalyzerScreen extends StatefulWidget {
  @override
  _ReportAnalyzerScreenState createState() => _ReportAnalyzerScreenState();
}

class _ReportAnalyzerScreenState extends State<ReportAnalyzerScreen> {
  final TextEditingController _descController = TextEditingController();
  List<XFile> _images = [];
  String _response = '';
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked != null) {
      setState(() {
        _images = picked;
      });
    }
  }
Future<void> _analyzeReport() async {
  setState(() {
    _isLoading = true;
    _response = '';
  });

  var uri = Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/analyze/report');
  var request = http.MultipartRequest('POST', uri);
  request.fields['description'] = _descController.text;

  for (var img in _images) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'images',
        img.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
  }

  final streamedResponse = await request.send();
  final stream = streamedResponse.stream.transform(utf8.decoder);

  stream.listen((chunk) {
    final lines = LineSplitter.split(chunk);
    for (var line in lines) {
      if (line.startsWith('data:')) {
        try {
          final jsonData = json.decode(line.substring(5).trim());
          final content = jsonData['content'];
          if (content != null && content is String) {
            setState(() {
              _response += content;
            });
          }
        } catch (e) {
          print('JSON parsing error: $e');
        }
      }
    }
  }, onDone: () {
    setState(() {
      _isLoading = false;
    });
  }, onError: (e) {
    setState(() {
      _isLoading = false;
      _response = 'Error: $e';
    });
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report Analyzer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Describe the situation...'),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _images.map((img) => Image.file(File(img.path), width: 80, height: 80)).toList(),
            ),
            TextButton.icon(
              icon: Icon(Icons.add_a_photo),
              label: Text('Add Images'),
              onPressed: _pickImages,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeReport,
              child: Text('Analyze Report'),
            ),
            SizedBox(height: 20),
            if (_isLoading) LinearProgressIndicator(),
            if (_response.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                color: Colors.grey[200],
                child: Text(_response),
              ),
          ],
        ),
      ),
    );
  }
}
