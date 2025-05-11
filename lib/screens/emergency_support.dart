import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

class EmergencySupportPage extends StatefulWidget {
  final String role;

  const EmergencySupportPage({Key? key, required this.role}) : super(key: key);

  @override
  State<EmergencySupportPage> createState() => _EmergencySupportPageState();
}

class _EmergencySupportPageState extends State<EmergencySupportPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String _recordedFilePath = '';
  bool _isLoading = false;
  String _situationDescription = '';
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioRecorder.openRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String> _getRecordingPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/recording_$timestamp.aac';
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _sendQuickAlert() async {
    try {
      final position = await getCurrentPosition();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      final name = prefs.getString('name') ?? 'Unknown';
      final contact = prefs.getString('phone') ?? 'Unknown';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('all data : ${prefs.getKeys()}'),
        ),
      );
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notify'),
      );
      request.fields.addAll({
        'user_id': userId.toString(),
        'role': widget.role,
        'coordinate': '${position.latitude},${position.longitude}',
        'notification': 'Emergency alert from $name',
        'status': 'pending',
        'name': name,
        'contact': contact,
      });

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        _showSuccessDialog('Alert sent successfully! Emergency services have been notified.');
      } else {
        _showErrorDialog('Failed to send alert. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final path = await _getRecordingPath();
        await _audioRecorder.startRecorder(
          toFile: path,
          codec: Codec.aacADTS,
          bitRate: 128000,
          sampleRate: 44100,
        );
        setState(() {
          _isRecording = true;
          _recordedFilePath = path;
        });
      } else {
        _showErrorDialog('Microphone permission denied.');
      }
    } catch (e) {
      _showErrorDialog('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      _showRecordingDialog();
    } catch (e) {
      _showErrorDialog('Error stopping recording: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      _showImagePreviewDialog();
    }
  }

  Future<void> _sendDetailedReport() async {
    if (_situationDescription.isEmpty) {
      _showErrorDialog('Please describe the situation');
      return;
    }

    try {
      final position = await getCurrentPosition();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      final name = prefs.getString('name') ?? 'Unknown';
      final contact = prefs.getString('phone') ?? 'Unknown';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notify'),
      );

      request.fields.addAll({
        'user_id': userId.toString(),
        'role': widget.role,
        'coordinate': '${position.latitude},${position.longitude}',
        'notification': _situationDescription,
        'status': 'pending',
        'name': name,
        'contact': contact,
      });

      if (_image != null) {
        final extension = _image!.path.split('.').last.toLowerCase();
        String contentType = 'jpeg';
        if (extension == 'png') contentType = 'png';
        if (extension == 'gif') contentType = 'gif';
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _image!.path,
          contentType: MediaType('image', contentType),
        ));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        _showSuccessDialog('Detailed report sent successfully!');
        setState(() {
          _situationDescription = '';
          _descriptionController.clear();
          _image = null;
        });
      } else {
        _showErrorDialog('Failed to send report. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRecordingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recording Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Would you like to send this recording?'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _sendRecording();
              },
              child: Text('Send Recording'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showImagePreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Image Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(_image!, height: 200),
            SizedBox(height: 10),
            Text('Would you like to send this image?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendImage();
            },
            child: Text('Send Image'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRecording() async {
    if (_recordedFilePath.isEmpty) {
      _showErrorDialog('No recording available');
      return;
    }

    try {
      final position = await getCurrentPosition();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      final name = prefs.getString('name') ?? 'Unknown';
      final contact = prefs.getString('phone') ?? 'Unknown';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notify'),
      );

      request.fields.addAll({
        'user_id': userId.toString(),
        'role': widget.role,
        'coordinate': '${position.latitude},${position.longitude}',
        'notification': 'Voice recording from $name',
        'status': 'pending',
        'name': name,
        'contact': contact,
      });

      final audioFile = File(_recordedFilePath);
      if (await audioFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _recordedFilePath,
          contentType: MediaType('audio', 'aac'),
        ));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        _showSuccessDialog('Voice recording sent successfully!');
        setState(() {
          _recordedFilePath = '';
        });
        // Clean up the temporary file
        await audioFile.delete();
      } else {
        _showErrorDialog('Failed to send recording. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _sendImage() async {
    if (_image == null) {
      _showErrorDialog('No image selected');
      return;
    }

    try {
      final position = await getCurrentPosition();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      final name = prefs.getString('name') ?? 'Unknown';
      final contact = prefs.getString('phone') ?? 'Unknown';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notify'),
      );

      request.fields.addAll({
        'user_id': userId.toString(),
        'role': widget.role,
        'coordinate': '${position.latitude},${position.longitude}',
        'notification': 'Image from $name',
        'status': 'pending',
        'name': name,
        'contact': contact,
      });

      // Get the file extension
      final extension = _image!.path.split('.').last.toLowerCase();
      final contentType = _getImageContentType(extension);

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _image!.path,
        contentType: MediaType('image', contentType),
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        _showSuccessDialog('Image sent successfully!');
        setState(() {
          _image = null;
        });
      } else {
        _showErrorDialog('Failed to send image. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  String _getImageContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Support'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Support Options',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildEmergencyCard(
              title: 'Quick Alert',
              description: 'Send immediate alert with your location',
              icon: Icons.warning,
              color: Colors.red,
              onTap: _sendQuickAlert,
            ),
            SizedBox(height: 16),
            _buildEmergencyCard(
              title: 'Voice Recording',
              description: 'Record and send voice message',
              icon: Icons.mic,
              color: Colors.blue,
              onTap: _isRecording ? _stopRecording : _startRecording,
              trailing: _isRecording ? Icon(Icons.stop, color: Colors.red) : null,
            ),
            SizedBox(height: 16),
            _buildEmergencyCard(
              title: 'Upload Image',
              description: 'Send image of the situation',
              icon: Icons.image,
              color: Colors.green,
              onTap: _pickImage,
            ),
            SizedBox(height: 16),
            _buildDetailedReportCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedReportCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description, color: Colors.purple, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detailed Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Describe the situation in detail',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the situation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _situationDescription = value;
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.upload),
                    label: Text('Upload Image'),
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.send),
                    label: Text('Send Report'),
                    onPressed: _sendDetailedReport,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 