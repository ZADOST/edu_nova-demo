import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: AppTheme.deepTeal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Latest Announcements', style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildAnnouncement('Campus Closure', 'The campus will be closed on Friday for cleaning and maintenance.'),
          _buildAnnouncement('Exam Timetable', 'New exam timetable has been published. Please check your schedule.'),
          _buildAnnouncement('New Library Hours', 'The library now opens from 8:00 AM to 8:00 PM daily.'),
        ],
      ),
    );
  }

  Widget _buildAnnouncement(String title, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.mintGlow, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
