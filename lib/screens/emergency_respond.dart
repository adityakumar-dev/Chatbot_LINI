import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class EmergencyResponsePage extends StatefulWidget {
  EmergencyResponsePage({
    Key? key,
  }) : super(key: key);

  @override
  _EmergencyResponsePageState createState() => _EmergencyResponsePageState();
}

class _EmergencyResponsePageState extends State<EmergencyResponsePage> with RouteAware {
  List<dynamic> _notifications = [];
  late String username = '';
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when the route is active again
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _fetchNotifications();
    }
  }

  Future<void> _fetchNotifications() async {
 final prefs = await  SharedPreferences.getInstance();
 username = prefs.getString('username') ?? '';

    setState(() => _isLoading = true);
    final response = await http.get(
      Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notify/all'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _notifications = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch notifications")));
    }
  }

  Future<void> _takeAction(int id) async {
    final response = await http.post(
      Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notification/acknowledge'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'username': username}),
    );
    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You took this action.")));
      _fetchNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to take action")));
    }
  }

  Future<void> _completeAction(int id) async {
    Navigator.pop(context);
    context.push('/admin-complete-emergency', extra: id.toString());
  }

  Color _getCardColor(Map notif) {
    if (notif['status'] == 'completed') return Colors.green.shade100;
    if (notif['status'] == 'read' && notif['action_taken_by'] == username) return Colors.yellow.shade100;
    if (notif['status'] == 'unread') return Colors.red.shade100;
    return Colors.grey.shade200;
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'read':
        return 'In Progress';
      case 'unread':
        return 'New Alert';
      case 'completed':
        return 'Resolved';
      default:
        return 'Unknown';
    }
  }

  void _showActionDialog(Map notif) {
    final isMine = notif['action_taken_by'] == username;
    final isUnread = notif['status'] == 'unread';
    final isCompleted = notif['status'] == 'completed';

    if (isCompleted || (!isMine && !isUnread)) {
      // Already taken by someone else
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("This emergency is already taken.")));
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isMine ? 'Complete Emergency' : 'Take Action?'),
        content: Text(
          isMine
              ? 'Would you like to mark this emergency as completed?'
              : 'Do you want to take responsibility for this emergency?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isMine ? Colors.orange : Colors.red,
            ),
            onPressed: () {
              if (isMine) {
                _completeAction(notif['id']);
              } else {
                _takeAction(notif['id']);
              }
            },
            child: Text(isMine ? "Complete" : "Take Action"),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map notif) {
    return Card(
      color: _getCardColor(notif),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          notif['notification'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Help Needed: ${notif['name']}"),

            Row(
              children: [
                Text("Contact : ${notif['contact']}"),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.call),
                  onPressed: () {
                    FlutterPhoneDirectCaller.callNumber(notif['contact']);
                  },
                ),
              ],
            ),
            
            
            Text("📍 Location: ${notif['coordinate']}"),
            ElevatedButton(onPressed: (){
          launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${notif['coordinate']}'));

            }, child: Text("View on Maps")),
            SizedBox(height: 4),
            Text("📌 Status: ${_formatStatus(notif['status'])}"),
            if (notif['action_taken_by'] != null)
              Text("👮 Responder: ${notif['action_taken_by']}"),
          ],
        ),
        trailing: notif['status'] == 'completed'
            ? Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: Icon(Icons.info, color: Colors.blue),
                onPressed: () => _showActionDialog(notif),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("Dashboard"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchNotifications),
          IconButton(onPressed: ()async{
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.clear();
            context.go('/login');
          }
          , icon: Icon(Icons.logout))
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text("No emergencies at the moment."))
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
                    },
                  ),
                ),
    );
  }
}
