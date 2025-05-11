import 'dart:convert';

import 'package:chatbot_lini/config/hive_configs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ContactScreens extends StatefulWidget {
  const ContactScreens({super.key});

  @override
  State<ContactScreens> createState() => _ContactScreensState();
}

class _ContactScreensState extends State<ContactScreens> {
   List<Map<String, String>> _contacts = [];

  void _addContact(String name, String phone)async {
    setState(() {
      _contacts.add({'name': name, 'phone': phone});
    });
    SharedPreferences prefs =await SharedPreferences.getInstance();
  final body = jsonEncode({
      'user_id' : prefs.getInt('user_id').toString(),
      'emergency_contacts' : _contacts
    });
    debugPrint(body);
    final response = await
  http.post(Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/user/add/emergency'),
      headers: {'Content-Type': 'application/json'},
      body: body
    );
    HiveConfigs.saveContactsData('contacts', _contacts);
  
  }@override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadContacts();
  }
  void _loadContacts() async {
    List<Map<String, String>> contacts = await HiveConfigs.getContactsData('contacts');
    setState(() {
      _contacts.clear();
      _contacts = contacts;
    });
  
  }



  void _removeContact(int index)async {
    setState(() {
      _contacts.removeAt(index);
    });
    SharedPreferences prefs =await SharedPreferences.getInstance();
  final body = jsonEncode({
      'user_id' : prefs.getInt('user_id').toString(),
      'emergency_contacts' : _contacts
    });
    debugPrint(body);
    final response = await
  http.post(Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/user/add/emergency'),
      headers: {'Content-Type': 'application/json'},
      body: body
    );
    HiveConfigs.saveContactsData('contacts', _contacts);

  }

  void _showAddContactSheet() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Add Emergency Contact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                TextFormField(
                  decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? "Enter a name" : null,
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.length < 10 ? "Enter a valid number" : null,
                  onChanged: (val) => phone = val,
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _addContact(name, phone);
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text("Save"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: Size.fromHeight(45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  Widget _buildContactCard(int index, Map<String, String> contact) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(Icons.contact_phone, color: Colors.teal),
        title: Text(contact['name']!),
        subtitle: Text(contact['phone']!),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeContact(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Contacts'),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.add),
          //   onPressed: _showAddContactSheet,
          //   tooltip: "Add Contact",
          // ),
        ],
      ),
      body: _contacts.isEmpty
          ? Center(
              child: Text(
                'No emergency contacts added yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              itemBuilder: (context, index) => _buildContactCard(index, _contacts[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactSheet,
        child: Icon(Icons.add),
        tooltip: "Add Emergency Contact",
      ),
    );
  }
}
