import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/admin/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _email,
          'password': _password,
        }),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful: ${res['user']['role']}')),
        );
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.clear();
        final user = res['user'];
        prefs.setString('username', user['username'] ?? '');
        prefs.setString('name', user['name'] ?? '');
        prefs.setString('role', user['role'] ?? '');
        prefs.setString('contact', user['contact'] ?? '');
        prefs.setString('location', user['location_cordinate'] ?? '');
        prefs.setString('official_id', user['official_id'] ?? '');
        prefs.setString('city', user['city'] ?? '');
        prefs.setString('email', user['email'] ?? '');
        prefs.setString('is_organization', user['is_organization'] ?? '');
        prefs.setString('created_at', user['created_at'] ?? '');
        prefs.setString('password', user['password'] ?? '');
        prefs.setInt('id', user['id'] ?? 0);
        
        debugPrint(res.toString());
        context.go('/admin-home', extra: user['username']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${res['detail']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        leading: Container(),
     backgroundColor: Colors.transparent,
     actions: [
      IconButton(onPressed: (){context.push('/login');}, icon: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text("User Login", style: TextStyle(color: Colors.black),))),
     ],
      ),
      // backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text("Admin Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 30),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Email"),
                    onSaved: (value) => _email = value ?? '',
                    validator: (value) => value!.isEmpty ? "Enter your email" : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Password"),
                    obscureText: true,
                    onSaved: (value) => _password = value ?? '',
                    validator: (value) => value!.isEmpty ? "Enter your password" : null,
                  ),
                  SizedBox(height: 30),
                  _loading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          child: Text("Login"),
                          style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
                        ),
                  Row(
                    children: [
                      Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          context.go('/admin-register');
                        },
                        child: Text("Sign Up Now!",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
