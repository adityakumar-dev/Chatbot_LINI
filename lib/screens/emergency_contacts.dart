import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> handleCall(String number, BuildContext context) async {
    if (await Permission.phone.isDenied) {
      await Permission.phone.request();
    } else if (await Permission.phone.isPermanentlyDenied) {
      await openAppSettings();
    } else if (await Permission.phone.isGranted) {
      await FlutterPhoneDirectCaller.callNumber(number);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final contacts = [
      // National
      {
        'title': 'Ambulance', 'number': '108', 'icon': Icons.local_hospital, 'color': Colors.redAccent
      },
      {
        'title': 'Police', 'number': '100', 'icon': Icons.local_police, 'color': Colors.blueAccent
      },
      {
        'title': 'Fire', 'number': '101', 'icon': Icons.fire_truck, 'color': Colors.orangeAccent
      },
      {
        'title': 'Women Helpline', 'number': '1091', 'icon': Icons.woman, 'color': Colors.pinkAccent
      },
      {
        'title': 'Child Helpline', 'number': '1098', 'icon': Icons.child_care, 'color': Colors.greenAccent
      },
      {
        'title': 'Senior Citizen Helpline', 'number': '14567', 'icon': Icons.elderly, 'color': Colors.purpleAccent
      },
      {
        'title': 'Railway Helpline', 'number': '139', 'icon': Icons.train, 'color': Colors.indigoAccent
      },
      {
        'title': 'Tourist Helpline', 'number': '1363', 'icon': Icons.tour, 'color': Colors.tealAccent
      },
      {
        'title': 'Anti Poison', 'number': '1066', 'icon': Icons.warning, 'color': Colors.amberAccent
      },
      {
        'title': 'AIDS Helpline', 'number': '1097', 'icon': Icons.health_and_safety, 'color': Colors.deepOrangeAccent
      },
      {
        'title': 'Disaster Management', 'number': '1078', 'icon': Icons.warning_amber, 'color': Colors.deepPurpleAccent
      },
      {
        'title': 'Road Accident Emergency', 'number': '1073', 'icon': Icons.car_crash, 'color': Colors.brown
      },
      {
        'title': 'Blood Requirement', 'number': '104', 'icon': Icons.bloodtype, 'color': Colors.red
      },
      {
        'title': 'Cyber Crime Helpline', 'number': '155260', 'icon': Icons.security, 'color': Colors.blueGrey
      },
      {
        'title': 'National Emergency Number', 'number': '112', 'icon': Icons.emergency, 'color': Colors.red
      },
      // Add more as needed, including state-level if desired
    ];

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : theme.primaryColor,
        elevation: 0,
        title: Text(
          'Emergency Contacts',
          style: TextStyle(color: !isDarkMode ? Colors.white : Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: !isDarkMode ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Emergency Contacts in India",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ...contacts.map((contact) => _buildContactCard(
                context,
                contact['title'] as String,
                contact['number'] as String,
                contact['icon'] as IconData,
                contact['color'] as Color,
                () => handleCall(contact['number'] as String, context),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, String title, String number, IconData icon, Color color, VoidCallback onCall) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isDarkMode ? Colors.white : color.withOpacity(0.2),
              radius: 25,
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.call, color: color),
              onPressed: onCall,
              tooltip: 'Call',
            ),
          ],
        ),
      ),
    );
  }
}
