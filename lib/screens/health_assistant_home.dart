import 'dart:convert';
import 'dart:io';
import 'package:another_telephony/telephony.dart';
import 'package:chatbot_lini/config/hive_configs.dart';
import 'package:chatbot_lini/providers/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthAssistantHome extends StatefulWidget {
  const HealthAssistantHome({super.key});

  @override
  State<HealthAssistantHome> createState() => _HealthAssistantHomeState();
}

class _HealthAssistantHomeState extends State<HealthAssistantHome> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String _chatbotResponse = "";
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _uploadImageAndGetResponse() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _chatbotResponse = "";
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://enabled-flowing-bedbug.ngrok-free.app/api/chatbot'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      setState(() {
        _chatbotResponse = data['response'] ?? "No response received.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _chatbotResponse = "Error: $e";
        _isLoading = false;
      });
    }
  }


  Future<void> handleCall(String number) async {
    if (await Permission.phone.isDenied) {
      await Permission.phone.request();
    } else if (await Permission.phone.isPermanentlyDenied) {
      await openAppSettings();
    } else if (await Permission.phone.isGranted) {
      await FlutterPhoneDirectCaller.callNumber(number);
    }
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> sendEmergencyAlerts(BuildContext context, Position position) async {
    final List<Map<String, String>> contacts = await HiveConfigs.getContactsData('contacts');
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String alertMessageString(String name, String contactName) =>
        "Emergency Alert $contactName! Please assist. I'm $name. "
        "Currently at location ${position.latitude},${position.longitude}. "
        "View me on Map: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

    PermissionStatus permission = await Permission.sms.request();
    if (permission.isDenied || permission.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("SMS permission denied."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String senderName = prefs.getString('name') ?? 'Someone in need';

    for (var contact in contacts) {
      final String phone = contact['phone'] ?? contact['contact'] ?? '';
      final String name = contact['name'] ?? '';
      if (phone.isNotEmpty) {
        await SmsService.sendSMS(
          phone,
          alertMessageString(senderName, name),
          onResult: (success, message) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : theme.primaryColor,
        elevation: 0,
        title: Text(
          'ResQ.Ai',
          style: TextStyle(color: !isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.contact_emergency_outlined, color: !isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              context.push('/contacts');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: !isDarkMode ? Colors.white : Colors.black),
            onPressed: () async {
              SharedPreferences preferences = await SharedPreferences.getInstance();
              preferences.clear();
              context.push('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Emergency Assistance",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _UrgencyCard(
                title: "Emergency",
                color: Colors.redAccent,
                icon: Icons.warning,
                onTap: () {},
                content: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.push('/emergency-contacts');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(child: Text("View All Official Helpline Numbers", style: TextStyle(color: Colors.red))),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_ios, color: Colors.red)
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: _EmergencyDialButton(
                            label: "Ambulance",
                            icon: Icons.local_hospital,
                            text: "108",
                            onTap: () async {
                              handleCall("108");
                            },
                          ),
                        ),
                        Flexible(
                          child: _EmergencyDialButton(
                            label: "Police",
                            icon: Icons.local_police,
                            text: "100",
                            onTap: () async {
                              await handleCall("100");
                            },
                          ),
                        ),
                        Flexible(
                          child: _EmergencyDialButton(
                            label: "Fire",
                            icon: Icons.fire_truck,
                            text: "101",
                            onTap: () async {
                              await handleCall("101");
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: Icon(Icons.warning),
                      label: Text("Send Emergency Alert"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(50),
                      ),
                      onPressed: () async {
                        Position position = await getCurrentPosition();
                        sendEmergencyAlerts(context, position);
                      },
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/user-help');
                        },
                        child: Text("Ask for help", style: TextStyle(color: Colors.red)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          side: BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _UrgencyCard(
                title: "First Emergency Support",
                color: Colors.purpleAccent,
                icon: Icons.support_agent,
                onTap: () {},
                content: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          context.push('/emergency-support/women-safety');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.woman, color: Colors.purpleAccent),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Women Safety", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text("Get immediate assistance for women's safety issues.", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          context.push('/emergency-support/medical-support');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.local_hospital, color: Colors.purpleAccent),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Road Accident / Medical Support", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text("Get help for road accidents and medical emergencies.", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          context.push('/emergency-support/police-support');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.local_police, color: Colors.purpleAccent),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Police Support", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text("Get immediate assistance from the police.", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _UrgencyCard(
                title: "FAQ (Critical & Accident)",
                color: Colors.orangeAccent,
                icon: Icons.info_outline,
                onTap: () {},
                content: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...["Chest Pain", "Breathing Issue", "Seizure", "High Fever", "Road Accident", "Burn Injury", "Bleeding or Cuts", "Animal Bite or Sting", "Women Safety Help", "Medical Help", "Fireman Help"].map((label) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _CriticalOption(label: label, isAccident: false),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: (){
                                    context.push('/report-scan');

                },
                child: _UrgencyCard(
                  title: "Chatbot (Scan Your Report)",
                  color: Colors.blueAccent,
                  icon: Icons.chat,
                  onTap: () {
                  },
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Scan Your Reports....", style: TextStyle(color: Colors.black,),),
                      Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black,)  // SizedBox(width: 10,)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "chatAssistant",
            onPressed: () {
              context.push('/chat');
            },
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.chat, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "voiceAssistant",
            onPressed: () {
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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

  const _EmergencyDialButton({required this.label, required this.icon, required this.text, required this.onTap});

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
          Text(text, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87))
        ],
      ),
    );
  }
}

class _CriticalOption extends StatelessWidget {
  final String label;
  final bool isAccident;

  const _CriticalOption({required this.label, required this.isAccident});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.push('/health-chat', extra: [label, isAccident]);
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
