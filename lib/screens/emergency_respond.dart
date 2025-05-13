import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

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
  late String adminRole = '';
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadAdminRole();
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
    if (notif['status'] == 'pending') return Colors.red.shade100;
    return Colors.grey.shade200;
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'read':
        return 'In Progress';
      case 'pending':
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
    final isTakenByOther = notif['action_taken_by'] != null && notif['action_taken_by'] != username;

    if (isCompleted || (!isUnread && isTakenByOther)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("This emergency is already taken.")));
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isMine ? 'Complete Emergency' : 'Take Action?',),
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
            child: Text(isMine ? "Complete" : "Take Action", style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map notif) {
    final bool isUrgent = notif['status'] == 'pending';
    final bool isInProgress = notif['status'] == 'read';
    final bool isCompleted = notif['status'] == 'completed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isUrgent ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUrgent 
          ? BorderSide(color: Colors.red.shade300, width: 2)
          : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Bar
          Container(
            decoration: BoxDecoration(
              color: isUrgent 
                ? Colors.red.shade50
                : isInProgress 
                  ? Colors.orange.shade50 
                  : Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isUrgent 
                    ? Icons.warning_rounded
                    : isInProgress 
                      ? Icons.pending_actions 
                      : Icons.check_circle,
                  color: isUrgent 
                    ? Colors.red 
                    : isInProgress 
                      ? Colors.orange 
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatStatus(notif['status']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUrgent 
                      ? Colors.red 
                      : isInProgress 
                        ? Colors.orange 
                        : Colors.green,
                  ),
                ),
                const Spacer(),
                Text(
                  notif['role'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency Message
                Text(
                  notif['notification'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // User Info Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              (notif['name'] as String).substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (notif['action_taken_by'] != null)
                                  Text(
                                    'Responder: ${notif['action_taken_by']}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => context.push('/admin-user-info', extra: notif['user_id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Section
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => FlutterPhoneDirectCaller.callNumber(notif['contact']),
                        icon: const Icon(Icons.phone),
                        label: Text(notif['contact']),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://www.google.com/maps/search/?api=1&query=${notif['coordinate']}')
                      ),
                      icon: const Icon(Icons.map),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                  ],
                ),

                // Media Section
                if (notif['user_image_path'] != null || notif['user_voice_path'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attached Media',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMedia(notif),
                      ],
                    ),
                  ),

                // Action Buttons
                if (!isCompleted)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showActionDialog(notif),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUrgent ? Colors.red : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              isUrgent ? 'Take Action' : 'Complete Emergency',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminRole = (prefs.getString('role') ?? '').toLowerCase();
    });
  }

  List<dynamic> get _filteredNotifications {
    if (adminRole.isEmpty) return _notifications;
    // Customize this logic as needed for your roles
    return _notifications.where((notif) {
      final notifRole = (notif['role'] ?? '').toLowerCase();
      if (adminRole == 'doctor' || adminRole == 'hospital staff') {
        return notifRole == 'doctor' ||
               notifRole == 'road accident/medical support' ||
               notifRole == 'hospital staff';
      }
      if (adminRole == 'police') {
        return notifRole == 'police';
      }
      if (adminRole == 'women safety' || adminRole == 'women-safety') {
        return notifRole == 'women safety' || notifRole == 'women-safety';
      }
      if (adminRole == 'road accident/medical support') {
        return notifRole == 'road accident/medical support';
      }
      // Add more role logic as needed
      return notifRole == adminRole;
    }).toList();
  }

  // Helper to get the file URL
  String getFileUrl(int id, String type) =>
    'https://enabled-flowing-bedbug.ngrok-free.app/api/notify/file/$id?file_type=$type';

  // Widget to show image or voice
  Widget _buildMedia(Map notif) {
    if (notif['user_image_path'] != null) {
      return GestureDetector(
        onTap: () async {
          final url = getFileUrl(notif['id'], 'image');
          // Show image in dialog
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          );
        },
        child: Image.network(
          getFileUrl(notif['id'], 'image'),
          height: 80,
          width: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
        ),
      );
    }
    if (notif['user_voice_path'] != null) {
      return IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: () async {
          final url = getFileUrl(notif['id'], 'voice');
          final player = AudioPlayer();
          await player.play(UrlSource(url));
        },
      );
    }
    return SizedBox.shrink();
  }

  // Update the status badge to be more visually appealing
  Widget _statusBadge(String status) {
    final Map<String, Map<String, dynamic>> statusConfig = {
      'pending': {
        'color': Colors.red,
        'text': 'Urgent',
        'icon': Icons.warning_rounded,
      },
      'read': {
        'color': Colors.orange,
        'text': 'In Progress',
        'icon': Icons.pending_actions,
      },
      'completed': {
        'color': Colors.green,
        'text': 'Resolved',
        'icon': Icons.check_circle,
      },
    };

    final config = statusConfig[status] ?? statusConfig['pending']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (config['color'] as Color).withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'] as IconData,
            size: 16,
            color: config['color'] as Color,
          ),
          const SizedBox(width: 4),
          Text(
            config['text'] as String,
            style: TextStyle(
              color: config['color'] as Color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              'Role: ${adminRole.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
          IconButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.clear();
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading emergencies...'),
                ],
              ),
            )
          : _filteredNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Active Emergencies',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull to refresh or tap the refresh button',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_filteredNotifications[index]);
                    },
                  ),
                ),
    );
  }
}
