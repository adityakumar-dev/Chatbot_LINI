import 'package:chatbot_lini/config/services/location_service.dart';
import 'package:chatbot_lini/providers/location_checker_provider.dart';
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : theme.primaryColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.settings, color: !isDarkMode ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(
                color: !isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: !isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Emergency Settings',
            icon: Icons.emergency,
            color: Colors.redAccent,
            children: [
              _SettingsTile(
                icon: Icons.question_mark,
                title: 'Emergency Questions',
                subtitle: 'Set up your security questions',
                onTap: () async {
                  final sharedPreferences = await SharedPreferences.getInstance();
                  final userId = sharedPreferences.getInt('user_id');
                  context.push('/user-question-emergency', extra: userId.toString());
                },
              ),
              _SettingsTile(
                icon: Icons.location_on,
                title: 'Emergency Contacts',
                subtitle: 'Manage your emergency contacts',
                onTap: () => context.push('/contacts'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Appearance',
            icon: Icons.palette,
            color: Colors.blueAccent,
            children: [
              _SettingsTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Toggle dark/light theme',
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Account',
            icon: Icons.person,
            color: Colors.purpleAccent,
            children: [
              _SettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out from your account',
                onTap: () async {
                  SharedPreferences preferences = await SharedPreferences.getInstance();
                  preferences.clear();
                 await LocationService.stopLocationService();
                                Provider.of<LocationCheckerProvider>(context,listen: false).updateLocationServiceStatus(false);

                  context.go('/login');
                },
                textColor: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDarkMode ? Colors.white : Colors.black;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? defaultTextColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: textColor ?? defaultTextColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? defaultTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.white60 : Colors.black54,
          fontSize: 12,
        ),
      ),
      trailing: trailing ?? (onTap != null
          ? Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            )
          : null),
    );
  }
} 