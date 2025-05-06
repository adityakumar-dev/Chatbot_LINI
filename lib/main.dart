import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot_lini/screens/splash_screen.dart';
import 'package:chatbot_lini/services/api_service.dart';
import 'package:chatbot_lini/providers/auth_provider.dart';
import 'package:chatbot_lini/providers/chat_provider.dart';
import 'package:chatbot_lini/providers/theme_provider.dart';
import 'package:chatbot_lini/config/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final apiService = ApiService(http.Client(), prefs);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(apiService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp.router(
      title: 'ChatBot Lini',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
