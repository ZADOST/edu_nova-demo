import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      body: _buildCurrentView(),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkCharcoal.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              backgroundColor: AppTheme.deepTeal.withValues(alpha: 0.8),
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.mintGlow,
              unselectedItemColor: AppTheme.pureWhite.withValues(alpha: 0.5),
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Child'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Attendance'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Grades'),
                BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Announcements'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 1:
        return _buildAttendanceView();
      case 2:
        return _buildGradesView();
      case 3:
        return _buildAnnouncementsView();
      default:
        return _buildChildProfileView();
    }
  }

  Widget _buildChildProfileView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Child Profile', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(radius: 40, backgroundColor: AppTheme.mintGlow, child: Icon(Icons.person, color: AppTheme.darkCharcoal, size: 40)),
                const SizedBox(height: 16),
                const Text('Lana Ahmed', style: TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Grade 10 · Science', style: TextStyle(color: AppTheme.pureWhite, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoTile('School', 'ZAS Tech International School'),
          _buildInfoTile('Class', '10th Grade Science'),
          _buildInfoTile('Teacher', 'Prof. Alan Turing'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showMessage('Viewing child profile details.'),
            child: const Text('VIEW PROFILE'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAttendanceView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Attendance Overview', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildInfoTile('Present', '92%'),
          _buildInfoTile('Absent', '3 days'),
          _buildInfoTile('Late', '1 day'),
          const SizedBox(height: 24),
          _buildInfoTile('Last Updated', 'Today, 08:30 AM'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showMessage('Viewing attendance history.'),
            child: const Text('VIEW ATTENDANCE HISTORY'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGradesView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Grades Summary', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildGradeRow('Biology', 'A'),
          _buildGradeRow('Mathematics', 'A-'),
          _buildGradeRow('English', 'B+'),
          _buildGradeRow('Computer Science', 'A'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showMessage('Opening detailed grade report.'),
            child: const Text('OPEN GRADE REPORT'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Announcements', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildAnnouncementItem('Parent–teacher meeting tomorrow at 5 PM.'),
          _buildAnnouncementItem('Child has an upcoming science fair this week.'),
          _buildAnnouncementItem('School bus schedule updated for next Monday.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/announcements'),
            child: const Text('VIEW ALL ANNOUNCEMENTS'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeRow(String subject, String grade) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(subject, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600)),
          Text(grade, style: const TextStyle(color: AppTheme.mintGlow, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 14)),
      ),
    );
  }
}
