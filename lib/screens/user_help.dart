import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  Position? _currentPosition;
  List<dynamic> _individuals = [];
  List<dynamic> _organizations = [];

  @override
  void initState() {
    super.initState();
    _fetchLocationAndAdmins();
  }

  Future<void> _fetchLocationAndAdmins() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    final response = await http.get(Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/admin/all')); // Replace with your real API
    if (response.statusCode == 200) {
      final List<dynamic> allAdmins = jsonDecode(response.body);
      List<dynamic> nearbyInd = [];
      List<dynamic> nearbyOrg = [];

      for (var admin in allAdmins) {
        final coords = admin['location_cordinate'].split(',');
        final double lat = double.parse(coords[0]);
        final double lon = double.parse(coords[1]);

        double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          lat, lon,
        );

        if (distance <= 50000) { // 50km radius
          admin['distance_km'] = (distance / 1000).toStringAsFixed(1);
          if (admin['is_organization'] == "true") {
            nearbyOrg.add(admin);
          } else {
            nearbyInd.add(admin);
          }
        }
      }

      setState(() {
        _individuals = nearbyInd;
        _organizations = nearbyOrg;
      });
    }
  }

  void _callNumber(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No contact number available.")));
      return;
    }
    
    FlutterPhoneDirectCaller.callNumber(phoneNumber);
  }

  Widget _buildAdminTile(admin) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.person_pin),
        title: Text(admin['username']),
        subtitle: Column(
          children: [
            Text("📍 ${admin['distance_km']} km • "),
          GestureDetector(
            onTap: ()async{
              // Open maps with coordinates
              String url = 'https://www.google.com/maps/search/?api=1&query=${admin['location_cordinate']}';
             await launchUrl(Uri.parse(url));
            },
            child: const Row(children: [Text("View on Maps",style: TextStyle(color: Colors.blueAccent, fontSize: 14),), SizedBox(width: 2,), Icon(Icons.location_on_outlined, color: Colors.blueAccent,)],))
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.call),
          onPressed: () => _callNumber(admin['contact']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Need Help?"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchLocationAndAdmins,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Optional: Open Rescue.AI chatbot screen
        },
        child: Icon(Icons.chat),
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLocationAndAdmins,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (_organizations.isNotEmpty) ...[
                    Text("Nearby Organizations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._organizations.map(_buildAdminTile).toList(),
                    SizedBox(height: 20),
                  ],
                  if (_individuals.isNotEmpty) ...[
                    Text("Nearby Individuals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ..._individuals.map(_buildAdminTile).toList(),
                  ],
                ],
              ),
            ),
    );
  }
}
