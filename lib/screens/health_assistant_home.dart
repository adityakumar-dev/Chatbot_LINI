import 'package:chatbot_lini/config/hive_configs.dart';
import 'package:chatbot_lini/providers/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:chatbot_lini/providers/location_checker_provider.dart';
import 'package:chatbot_lini/config/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';

class HealthAssistantHome extends StatefulWidget {
  const HealthAssistantHome({super.key});

  @override
  State<HealthAssistantHome> createState() => _HealthAssistantHomeState();
}

class _HealthAssistantHomeState extends State<HealthAssistantHome> {
  @override
  Widget build(BuildContext context) {
    final locationCheckerProvider = Provider.of<LocationCheckerProvider>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : colors.primary,
        elevation: 0,
        title: Text(
          'ResQ.Ai',
          style: TextStyle(
            color: isDarkMode ? colors.primary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: isDarkMode ? colors.primary : Colors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Location Tracking Card
            _LocationTrackingCard(
              isActive: locationCheckerProvider.isLocationServiceRunning,
              onToggle: () async {
                if (locationCheckerProvider.isLocationServiceRunning) {
                  locationCheckerProvider.updateLocationServiceStatus(false);
                  LocationService.stopLocationService();
                } else {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.get('user_id').toString();
                  if (userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please login first to use location service"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  locationCheckerProvider.updateLocationServiceStatus(true);
                  await LocationService.startLocationService(userId);
                }
              },
            ),
            const SizedBox(height: 24),

            // Emergency Section
            _EmergencySection(),

            // Support Services
            _SupportServicesSection(),

            // FAQ Section
            _FaqSection(),

            // Report Scanner
            _ReportScannerSection(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "chat",
            onPressed: () => context.push('/chat-history'),
            backgroundColor: colors.primary,
            child: const Icon(Icons.chat, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "voice",
            onPressed: () => context.push('/voice'),
            backgroundColor: colors.secondary,
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LocationTrackingCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _LocationTrackingCard({
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isActive
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [colors.primary, colors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isActive ? Icons.location_on : Icons.location_off,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? "Location Tracking Active" : "Enable Location Tracking",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isActive
                              ? "Your location is being shared with emergency contacts"
                              : "Enable to share your location during emergencies",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isActive ? Icons.toggle_on : Icons.toggle_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              if (isActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.timer, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Updates every minute",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: colors.error),
                const SizedBox(width: 8),
                Text(
                  "Emergency Assistance",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _EmergencyOptionCard(
              title: "Emergency Helplines",
              icon: Icons.contacts,
              color: colors.error,
              onTap: () => context.push('/emergency-contacts'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EmergencyQuickAction(
                    icon: Icons.local_hospital,
                    label: "Ambulance",
                    number: "108",
                    color: colors.error,
                    onTap: () => _callNumber("108"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EmergencyQuickAction(
                    icon: Icons.local_police,
                    label: "Police",
                    number: "100",
                    color: colors.primary,
                    onTap: () => _callNumber("100"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EmergencyQuickAction(
                    icon: Icons.fire_truck,
                    label: "Fire",
                    number: "101",
                    color: Colors.orange,
                    onTap: () => _callNumber("101"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.warning),
                label: const Text("SEND EMERGENCY ALERT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                 await Geolocator.requestPermission();
                  await Geolocator.isLocationServiceEnabled();
                  if(await Geolocator.isLocationServiceEnabled()){
                  
                    final position = await Geolocator.getCurrentPosition();
                    sendEmergencyAlerts(context, position);
                  }else{
                  
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Location service is not enabled")),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/user-help'),
              child: Text(
                "Need help? Contact Organization",
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    // Implement call functionality
    FlutterPhoneDirectCaller.callNumber(number);
  }

 
  Future<void> sendEmergencyAlerts(BuildContext context, Position position) async {
    try {
      final List<Map<String, String>> contacts = await HiveConfigs.getContactsData('contacts');
      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No emergency contacts found. Please add contacts first."),
          duration: Duration(seconds: 3),
        ));
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String senderName = prefs.getString('name') ?? 'Someone in need';

      // Check SMS permission status
      PermissionStatus permission = await Permission.sms.status;
      if (permission.isDenied) {
        permission = await Permission.sms.request();
      }

      if (permission.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("SMS permission is permanently denied. Please enable it in settings."),
          duration: Duration(seconds: 3),
        ));
        await openAppSettings();
        return;
      }

      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("SMS permission is required to send emergency alerts."),
          duration: Duration(seconds: 3),
        ));
        return;
      }

      String alertMessageString(String name, String contactName) =>
        "Emergency Alert $contactName! Please assist. I'm $name. "
        "Currently at location ${position.latitude},${position.longitude}. "
        "View me on Map: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      int successCount = 0;
      List<String> failedContacts = [];

      for (var contact in contacts) {
        final String phone = contact['phone'] ?? contact['contact'] ?? '';
        final String name = contact['name'] ?? '';
        
        if (phone.isNotEmpty) {
          try {
            await SmsService.sendSMS(
              phone,
              alertMessageString(senderName, name),
              onResult: (success, message) {
                if (success) {
                  successCount++;
                } else {
                  failedContacts.add(name);
                }
              },
            );
          } catch (e) {
            failedContacts.add(name);
          }
        }
      }

      // Show final status
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Emergency alerts sent to $successCount contact(s)"),
          duration: const Duration(seconds: 3),
        ));
      }
      
      if (failedContacts.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to send alerts to: ${failedContacts.join(", ")}"),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error sending emergency alerts: $e"),
        duration: const Duration(seconds: 3),
      ));
    }
  }
}

class _EmergencyOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyOptionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyQuickAction({
    required this.icon,
    required this.label,
    required this.number,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 24,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              Text(
                number,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportServicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.support_agent, color: colors.secondary),
                ),
                const SizedBox(width: 12),
                Text(
                  "Support Services",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.70,
              children: [
                _SupportServiceCard(
                  icon: Icons.woman,
                  title: "Women Safety",
                  description: "Immediate assistance for women's safety",
                  color: Colors.purple,
                  onTap: () => context.push('/emergency-support/women-safety'),
                ),
                _SupportServiceCard(
                  icon: Icons.local_hospital,
                  title: "Medical Support",
                  description: "Help for medical emergencies",
                  color: Colors.red,
                  onTap: () => context.push('/emergency-support/medical-support'),
                ),
                _SupportServiceCard(
                  icon: Icons.local_police,
                  title: "Police Support",
                  description: "Immediate police assistance",
                  color: Colors.blue,
                  onTap: () => context.push('/emergency-support/police-support'),
                ),
                _SupportServiceCard(
                  icon: Icons.psychology,
                  title: "Mental Health",
                  description: "Professional mental health support",
                  color: Colors.green,
                  onTap: () => context.push('/emergency-support/mental-health'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SupportServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final List<String> faqItems = const [
    "Chest Pain",
    "Breathing Issue",
    "Seizure",
    "High Fever",
    "Road Accident",
   
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  "Emergency FAQs",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: faqItems.map((item) => _FaqChip(item: item)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqChip extends StatelessWidget {
  final String item;

  const _FaqChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ActionChip(
      avatar: Icon(Icons.question_answer, size: 18, color: theme.colorScheme.primary),
      label: Text(item),
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      onPressed: () => context.push('/health-chat', extra: [item, false]),
    );
  }
}

class _ReportScannerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/report-scan'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.document_scanner, color: colors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Medical Report Scanner",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Scan your medical reports for analysis",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}