import 'package:chatbot_lini/screens/health_assistant_home.dart';
import 'package:chatbot_lini/screens/health_chat.dart';
import 'package:chatbot_lini/screens/voice_assistant.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chatbot_lini/screens/splash_screen.dart';
import 'package:chatbot_lini/screens/auth/login_screen.dart';
import 'package:chatbot_lini/screens/auth/auth_screen.dart';
import 'package:chatbot_lini/screens/chat_screen.dart';
import 'package:chatbot_lini/screens/history/history_screen.dart';
import 'package:chatbot_lini/screens/settings/settings_screen.dart';

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
      path: '/register',
      builder: (context, state) => const AuthScreen(),
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
      builder: (context, state) => const HealthAssistantHome(),
    ),
    GoRoute(path: '/health-chat',
      builder: (context, state){
      final userQuery =   state.extra as List;
      return HealthChatScreen(
        userQuery: userQuery[0],
isAccident: userQuery[1],      );
      },
    ),
  ],
); 