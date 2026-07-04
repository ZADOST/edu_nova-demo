import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        title: const Text('Timetable'),
        backgroundColor: AppTheme.deepTeal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Weekly Timetable', style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildClassRow('Monday', 'Advanced Java OOP', '08:00 - 09:30'),
          _buildClassRow('Tuesday', 'Database Systems', '10:00 - 11:30'),
          _buildClassRow('Wednesday', 'Software Engineering', '13:00 - 14:30'),
          _buildClassRow('Thursday', 'Mobile App Dev', '09:00 - 10:30'),
          _buildClassRow('Friday', 'Computer Networks', '11:00 - 12:30'),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildClassRow(String day, String subject, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day, style: const TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subject, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            Text(time, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
