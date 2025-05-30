import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationHistoryPage extends StatefulWidget {
  @override
  _NotificationHistoryPageState createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  late int userId;

  String getFileUrl(int id, String type) =>
      'https://enabled-flowing-bedbug.ngrok-free.app/api/notify/file/$id?file_type=$type';

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchNotifications();
  }

  Future<void> _loadUserIdAndFetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id') ?? 0;
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final response = await http.get(
      Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notify/all'),
    );
    if (response.statusCode == 200) {
      final allNotifications = jsonDecode(response.body);
      setState(() {
        _notifications = allNotifications.where((notif) => notif['user_id'] == userId).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch notifications")));
    }
  }

  Widget _buildMediaView(dynamic notif) {
    List<Widget> mediaWidgets = [];

    if (notif['user_image_path'] != null) {
      mediaWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Image.network(
              getFileUrl(notif['id'], 'user_image'),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Text('Failed to load image'),
            ),
            SizedBox(height: 10),
          ],
        ),
      );
    }

    if (notif['user_voice_path'] != null) {
      mediaWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Note:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(getFileUrl(notif['id'], 'user_voice')),
            // You can integrate an audio player here if needed
            SizedBox(height: 10),
          ],
        ),
      );
    }

    return mediaWidgets.isNotEmpty
        ? Column(children: mediaWidgets)
        : Text('No media available');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification History'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text('No notifications found.'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['notification'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text('Status: ${notif['status']}'),
                            Text('Time: ${notif['created_at']}'),
                            SizedBox(height: 10),
                            _buildMediaView(notif),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
