import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:chatbot_lini/providers/auth_provider.dart';
import 'package:chatbot_lini/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        
      ),
      body: ListView(
        children: [

          ListTile(
            leading: const Icon(Icons.question_mark),
            title: const Text('Emergency Questions'),
            onTap: () async {
              final sharedPreferences = await SharedPreferences.getInstance();
              final userId = sharedPreferences.getInt('user_id');
              context.push('/user-question-emergency', extra: userId.toString());
            },
          ),
                    const Divider(),

          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              SharedPreferences preferences = await SharedPreferences.getInstance();
              preferences.clear();
              context.push('/login');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
} 