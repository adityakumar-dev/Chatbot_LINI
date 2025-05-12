import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminRegisterPage extends StatefulWidget {
  @override
  _AdminRegisterPageState createState() => _AdminRegisterPageState();
}

class _AdminRegisterPageState extends State<AdminRegisterPage> {
  final TextEditingController username = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController officialIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
TextEditingController nameController = TextEditingController();
  String selectedRole = 'Doctor';
  String selectedCity = 'Dehradun';
  bool isOrganization = false;
  bool isLoading = false;

  final List<String> roles = [
    'Doctor',
    'Police',
    'Women Safety',
    'Road Accident/Medical Support',
    'Emergency Dispatcher',
    'Hospital Staff',
  ];
  final List<String> cities = ['Dehradun', 'Haridwar', 'Rishikesh', 'Nainital'];

  Future<void> _handleRegister() async {
    if (nameController.text.isEmpty ||
        contactController.text.isEmpty ||
        officialIdController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Enable location services to register.'),
        ));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Location permission denied.'),
          ));
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();

      final data = {
        "username": username.text,
        "password": passwordController.text,
        "official_id": officialIdController.text,
        "role": selectedRole,
        "city": selectedCity,
        "email": emailController.text,
        "contact": contactController.text,
        "location_cordinate": "${position.latitude},${position.longitude}",
        "name": nameController.text,
        "is_organization": isOrganization.toString()
      };
debugPrint(data.toString());
      final response = await http.post(
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/admin/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
           prefs.setString('username', username.text);
        prefs.setString('name', nameController.text);
        prefs.setString('role', "admin");
        prefs.setString('contact', contactController.text);
        prefs.setString('location', "${position.latitude},${position.longitude}");
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Registered successfully! ID: ${responseData['user_id']}'),
        ));
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${errorData['detail']}'),
        ));
        debugPrint('Error: ${errorData['detail']}');
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred: $e'),
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('Admin Registration'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
       actions: [
      IconButton(onPressed: (){context.push('/admin-login');}, icon: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text("Admin Login", style: TextStyle(color: Colors.black),))),
     ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(
                isOrganization ? 'Registering as Organization' : 'Registering as Individual',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              value: isOrganization,
              onChanged: (val) => setState(() => isOrganization = val),
            ),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: _inputDecoration(isOrganization ? 'Organization Name' : 'Full Name'),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Emergency Contact Number'),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: officialIdController,
                    decoration: _inputDecoration('Official ID (e.g., License or Badge ID)'),
                  ),
                  const SizedBox(height: 15),
                  
                   TextField(
                    controller: emailController,
                    decoration: _inputDecoration('Email or Mobile'),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: username,
                    decoration: _inputDecoration('username'),
                  ),

                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('Password'),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: _inputDecoration('Select Role'),
                    items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: _inputDecoration('City'),
                    items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                    onChanged: (val) => setState(() => selectedCity = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _handleRegister,
                    icon: Icon(Icons.location_on),
                    label: Text('Register & Share Location', style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
