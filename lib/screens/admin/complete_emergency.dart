import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart'; // ← Added

class CompleteEmergencyPage extends StatefulWidget {
  final String notificationId;

  const CompleteEmergencyPage({required this.notificationId});

  @override
  State<CompleteEmergencyPage> createState() => _CompleteEmergencyPageState();
}

class _CompleteEmergencyPageState extends State<CompleteEmergencyPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _coordinateController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  File? _imageFile;
  bool _isSubmitting = false;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {

  });
}
Future<void> _fetchLocation(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location services are disabled.")),
    );
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
  }

  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location permission permanently denied.")),
    );
    return;
  }

  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  _coordinateController.text = "${position.latitude},${position.longitude}";
}

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    var uri = Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notification/complete');

    var request = http.MultipartRequest('POST', uri);
    request.fields['notification_id'] = widget.notificationId.toString();
    request.fields['last_admin_coordinate'] = _coordinateController.text.trim();
    request.fields['action_details'] = _detailsController.text.trim();

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image_file',
        _imageFile!.path,
        filename: basename(_imageFile!.path),
      ));
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Marked as completed")));
      Navigator.pop(context, true); // indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to complete")));
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _coordinateController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        _fetchLocation(context);
    return Scaffold(
      appBar: AppBar(title: Text("Complete Emergency")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Coordinates (auto-filled)", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _coordinateController,
                decoration: InputDecoration(hintText: "e.g. 30.3425,77.9400"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16),
              Text("Action Details", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: InputDecoration(hintText: "What actions did you take?"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16),
              Text("Upload Image (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ElevatedButton(onPressed: _pickImage, child: Text("Pick Image")),
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(basename(_imageFile!.path), style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              SizedBox(height: 24),
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () => _submitForm(context),
                      child: Text("Submit",style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
