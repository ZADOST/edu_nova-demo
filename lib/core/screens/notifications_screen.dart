import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.deepTeal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Recent Notifications', style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildNotification('New message from principal', 'Your request has been received and is under review.'),
          _buildNotification('Attendance reminder', 'You have 2 unmarked classes today.'),
          _buildNotification('System update', 'EduNova will receive an update after 10:00 PM.'),
        ],
      ),
    );
  }

  Widget _buildNotification(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: ListTile(
          title: Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
          trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.pureWhite),
          onTap: () {},
        ),
      ),
    );
  }
}
