import 'package:chatbot_lini/screens/admin/user_info_screen.dart';
import 'package:chatbot_lini/screens/complete_emergency.dart';
import 'package:chatbot_lini/screens/contact_screens.dart';
import 'package:chatbot_lini/screens/emergency_respond.dart';
import 'package:chatbot_lini/screens/admin_login.dart';
import 'package:chatbot_lini/screens/admin_register.dart';
import 'package:chatbot_lini/screens/health_assistant_home.dart';
import 'package:chatbot_lini/screens/health_chat.dart';
import 'package:chatbot_lini/screens/report_analyzer.dart';
import 'package:chatbot_lini/screens/user_help.dart';
import 'package:chatbot_lini/screens/voice_assistant.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chatbot_lini/screens/splash_screen.dart';
import 'package:chatbot_lini/screens/auth/login_screen.dart';
import 'package:chatbot_lini/screens/chat_screen.dart';
import 'package:chatbot_lini/screens/history/history_screen.dart';
import 'package:chatbot_lini/screens/settings/settings_screen.dart';
import 'package:chatbot_lini/screens/emergency_contacts.dart';
import 'package:chatbot_lini/screens/emergency_support.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/voice',
      builder: (context, state) =>  VoiceAssistantApp(),
    ),
    GoRoute(
      path: '/health',
      builder: (context, state) =>  HealthAssistantHome(),
    ),
    GoRoute(path: '/health-chat',
      builder: (context, state){
      final userQuery =   state.extra as List;
      return HealthChatScreen(
        userQuery: userQuery[0],
isAccident: userQuery[1],      );
      },
    ),
    GoRoute(path: '/admin-register', 
      builder: (context, state) =>  AdminRegisterPage(),
    ),
   GoRoute(path: '/user-help', 
      builder: (context, state) =>  HelpScreen(),
    ),

    GoRoute(path: '/admin-login', 
      builder: (context, state) =>  AdminLoginPage(),
    ),
      GoRoute(path: '/admin-complete-emergency', 
      builder: (context, state){
       final id = state.extra as String;
        return CompleteEmergencyPage(notificationId: id.toString(),);
      },
    ),
    
    GoRoute(
  path: '/admin-home',
  builder: (context, state) {
    return EmergencyResponsePage();
  }, // Replace with actual name
),
GoRoute(
  path: '/contacts',
  builder: (context, state) {
    return ContactScreens();
  }, // Replace with actual name
),
GoRoute(
  path: '/emergency-contacts',
  builder: (context, state) => const EmergencyContactsScreen(),
),

GoRoute(
  path: '/report-scan',
  builder: (context, state) =>  ReportAnalyzerScreen(),
),
GoRoute(
  path: '/emergency-support/:role',
  builder: (context, state) {
    final role = state.pathParameters['role'];
    return EmergencySupportPage(role: role ?? '');
  },
),
GoRoute(
  path: '/admin-user-info',
  builder: (context, state) {
    final userId = state.extra as int;
    return UserInfoScreen(userId: userId);
  },
),
  ],
); 