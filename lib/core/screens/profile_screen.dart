import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.deepTeal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('My Profile', style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(radius: 40, backgroundColor: AppTheme.mintGlow, child: Icon(Icons.person, color: AppTheme.darkCharcoal, size: 40)),
                const SizedBox(height: 16),
                const Text('User Name', style: TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Role: EduNova Member', style: TextStyle(color: AppTheme.pureWhite, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Email', 'user@example.com'),
          _buildDetailRow('Phone', '+964 770 000 0000'),
          _buildDetailRow('Department', 'Computer Education'),
          _buildDetailRow('University', 'Tishk International University'),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
            Text(subtitle, style: const TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
