import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthAssistantHome extends StatelessWidget {
  const HealthAssistantHome({super.key});

  Future<void> handleCall(String number) async {
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

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : theme.primaryColor,
        elevation: 0,
        title: Text(
          'ResQ.Ai',
          style: TextStyle(color: !isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Assistance Type",
              style: TextStyle(
                fontSize: 22,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Emergency Section
            _UrgencyCard(
              title: "Emergency",
              color: Colors.redAccent,
              icon: Icons.warning,
              onTap: () {
                // Show emergency call options
              },
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _EmergencyDialButton(
                    label: "Ambulance",
                    icon: Icons.local_hospital,
                    text: "108",
                    onTap: () async{
                    handleCall("108");
                    },
                  ),
                  _EmergencyDialButton(
                    label: "Police",
                    icon: Icons.local_police,
                    text: "100",
                    onTap: ()async {
                     await handleCall("100");
                    },
                  ),
                  _EmergencyDialButton(
                    label: "Fire",
                    icon: Icons.fire_truck,
                    text: "101",
                    onTap: () async{
                     await handleCall("101");
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Critical Section
            _UrgencyCard(
              title: "Critical",
              color: Colors.orangeAccent,
              icon: Icons.health_and_safety,
              onTap: () {},
              content: Wrap(
                spacing: 10,
                children: [
                  _CriticalOption(label: "Chest Pain", isAccident: true),
                  _CriticalOption(label: "Breathing Issue", isAccident:  false,),
                  _CriticalOption(label: "Seizure", isAccident: false,),
                  _CriticalOption(label: "High Fever", isAccident:  false,),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Normal Section
            _UrgencyCard(
              title: "Accident",
              color: Colors.pink,
              icon: Icons.help_outline_outlined,
              onTap: () {},
              content: Wrap(
                spacing: 10,
                children: [
                  _CriticalOption(label: "Road Accident",isAccident: true,),
                  _CriticalOption(label: "Burn Injury",isAccident: true,),
                  _CriticalOption(label: "Bleeding or Cuts",isAccident: true,),
                  _CriticalOption(label: "Animal Bite or Sting",isAccident: true,),
                  
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "chatAssistant",
            onPressed: () {
              // Launch Chat Assistant
              context.push('/chat');
            },
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.chat, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "voiceAssistant",
            onPressed: () {
              // Launch Voice Assistant
              context.push('/voice');
            },
            backgroundColor: Colors.greenAccent,
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _UrgencyCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final Widget content;
  final VoidCallback onTap;

  const _UrgencyCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}

class _EmergencyDialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String text;

  const _EmergencyDialButton({required this.label, required this.icon,required this.text , required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: isDarkMode ? Colors.white : Colors.redAccent.withOpacity(0.1),
            radius: 25,
            child: Icon(icon, color: Colors.redAccent),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          ),
          Text(text,   style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          )
        ],
      ),
    );
  }
}

class _CriticalOption extends StatelessWidget {
  final String label;
 final bool isAccident;

  const _CriticalOption({required this.label,required this.isAccident });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: (){
           context.push('/health-chat', extra:[ label,isAccident]);
       
      },
      child: Chip(
        backgroundColor: isDarkMode ? Colors.white12 : Colors.grey[200],
        label: Text(
          label,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
