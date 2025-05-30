import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

class EmergencyResponsePage extends StatefulWidget {
  const EmergencyResponsePage({Key? key}) : super(key: key);

  @override
  _EmergencyResponsePageState createState() => _EmergencyResponsePageState();
}

class _EmergencyResponsePageState extends State<EmergencyResponsePage> with RouteAware {
  List<dynamic> _notifications = [];
  late String username = '';
  late String adminRole = '';
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentPlayingId;

  @override
  void initState() {
    super.initState();
    _loadAdminRole();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _fetchNotifications();
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      username = prefs.getString('username') ?? '';

      setState(() => _isLoading = true);
      final response = await http.get(
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notify/all'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = List.from(data)..sort((a, b) {
            if (a['status'] == 'pending' && b['status'] != 'pending') return -1;
            if (b['status'] == 'pending' && a['status'] != 'pending') return 1;
            return 0;
          });
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _takeAction(int id) async {
    try {
      final response = await http.post(
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/notification/acknowledge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'username': username}),
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully took action on the emergency'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchNotifications();
      } else {
        throw Exception('Failed to take action');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeAction(int id) async {
    if (mounted) {
      Navigator.pop(context);
      context.push('/admin-complete-emergency', extra: id.toString());
    }
  }

  Color _getCardColor(Map notif) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (notif['status'] == 'completed') {
      return isDarkMode ? Colors.green.shade900 : Colors.green.shade50;
    }
    if (notif['status'] == 'read' && notif['action_taken_by'] == username) {
      return isDarkMode ? Colors.amber.shade900 : Colors.amber.shade50;
    }
    if (notif['status'] == 'pending') {
      return isDarkMode ? Colors.red.shade900 : Colors.red.shade50;
    }
    return isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50;
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'read':
        return 'In Progress';
      case 'unread':
      case 'pending':
        return 'New Alert';
      case 'completed':
        return 'Resolved';
      default:
        return 'Unknown';
    }
  }

  Future<void> _handleMapNavigation(String coordinates) async {
    try {
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$coordinates');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleCall(String phoneNumber) async {
    try {
      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contact number provided')),
        );
        return;
      }

      // Clean the phone number
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      if (cleanNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid phone number format')),
        );
        return;
      }

      final result = await FlutterPhoneDirectCaller.callNumber(cleanNumber);
      if (result != null && result == true) {
        throw Exception('Failed to make call');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making call: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _playAudio(String id) async {
    if (_isPlaying && _currentPlayingId == id) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentPlayingId = null;
      });
      return;
    }

    try {
      await _audioPlayer.stop();
      final url = getFileUrl(int.parse(id), 'voice');
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _isPlaying = true;
        _currentPlayingId = id;
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
          _currentPlayingId = null;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildEmergencyCard(Map notif) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final contact = notif['contact']?.toString() ?? '';

    return Card(
      color: _getCardColor(notif),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with status and timestamp
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildStatusBadge(notif['status']),
                const Spacer(),
                if (notif['created_at'] != null)
                  Text(
                    DateFormat('MMM d, h:mm a').format(DateTime.parse(notif['created_at'])),
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency message
                Text(
                  notif['notification'] ?? 'No description provided',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // User Info Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          ((notif['name'] as String?) ?? '').isNotEmpty
                              ? (notif['name'] as String).substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['name'] ?? 'Anonymous',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (notif['action_taken_by'] != null)
                              Text(
                                'Responder: ${notif['action_taken_by']}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (notif['user_id'] != null)
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'View User Info',
                          onPressed: () => context.push('/admin-user-info', extra: notif['user_id']),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contact information
                _buildInfoRow(
                  Icons.person,
                  'Name',
                  notif['name'] ?? '',
                  textColor,
                ),
                _buildInfoRow(
                  Icons.phone,
                  'Contact',
                  contact,
                  textColor,
                  trailing: contact.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.call),
                          color: theme.colorScheme.primary,
                          tooltip: 'Call $contact',
                          onPressed: () => _handleCall(contact),
                        )
                      : null,
                ),
                _buildInfoRow(
                  Icons.location_on,
                  'Location',
                  notif['coordinate'] ?? '',
                  textColor,
                  trailing: notif['coordinate']?.isNotEmpty == true
                      ? TextButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text('View on Maps'),
                          onPressed: () => _handleMapNavigation(notif['coordinate']),
                        )
                      : null,
                ),

                // Media content
                if (notif['user_image_path'] != null || notif['user_voice_path'] != null)
                  _buildMediaContent(notif),

                const Divider(height: 32),

                // Action buttons
                _buildActionButtons(notif),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    color: value.isEmpty ? Colors.grey : textColor,
                    fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null && value.isNotEmpty) trailing,
        ],
      ),
    );
  }

  Widget _buildMediaContent(Map notif) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attached Media',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (notif['user_image_path'] != null)
            GestureDetector(
              onTap: () => _showImageDialog(notif['id']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  getFileUrl(notif['id'], 'image'),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
            ),
          if (notif['user_voice_path'] != null)
            ElevatedButton.icon(
              icon: Icon(_isPlaying && _currentPlayingId == notif['id'].toString()
                  ? Icons.stop
                  : Icons.play_arrow),
              label: Text(
                _isPlaying && _currentPlayingId == notif['id'].toString()
                    ? 'Stop Audio'
                    : 'Play Audio',
              ),
              onPressed: () => _playAudio(notif['id'].toString()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _showImageDialog(int id) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                getFileUrl(id, 'image'),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map notif) {
    final isMine = notif['action_taken_by'] == username;
    final isUnread = notif['status'] == 'unread';
    final isCompleted = notif['status'] == 'completed';
    final isTakenByOther = notif['action_taken_by'] != null && notif['action_taken_by'] != username;

    if (isCompleted) {
      return const Center(
        child: Chip(
          label: Text('Emergency Resolved'),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white),
        ),
      );
    }

    if (isTakenByOther) {
      return Center(
        child: Chip(
          label: Text('Handled by ${notif['action_taken_by']}'),
          backgroundColor: Colors.orange,
          labelStyle: const TextStyle(color: Colors.white),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isMine)
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Completed'),
            onPressed: () => _completeAction(notif['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          )
        else if (isUnread)
          ElevatedButton.icon(
            icon: const Icon(Icons.emergency),
            label: const Text('Take Action'),
            onPressed: () => _takeAction(notif['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String text = _formatStatus(status);

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'read':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'pending':
      case 'unread':
        color = Colors.red;
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper to get the file URL
  String getFileUrl(int id, String type) =>
      'https://enabled-flowing-bedbug.ngrok-free.app/api/notify/file/$id?file_type=$type';

  Future<void> _loadAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminRole = (prefs.getString('role') ?? '').toLowerCase();
    });
  }

  List<dynamic> get _filteredNotifications {
    if (adminRole.isEmpty) return _notifications;
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
      return notifRole == adminRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Emergencies',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull to refresh or tap the refresh button to check again',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                      return _buildEmergencyCard(_filteredNotifications[index]);
                    },
                  ),
                ),
    );
  }
}