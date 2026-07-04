import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.deepTeal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Application Settings', style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildOption(context, Icons.person, 'Account', 'Manage your profile and account settings.'),
          _buildOption(context, Icons.notifications, 'Notifications', 'Control your app notifications.'),
          _buildOption(context, Icons.palette, 'Theme', 'Switch between light and dark modes.'),
          _buildOption(context, Icons.lock, 'Security', 'Manage password and session settings.'),
          _buildOption(context, Icons.info, 'About EduNova', 'View app version and branding details.'),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.mintGlow),
          title: Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
          trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.pureWhite),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title page will be added soon.')),
          ),
        ),
      ),
    );
  }
}
