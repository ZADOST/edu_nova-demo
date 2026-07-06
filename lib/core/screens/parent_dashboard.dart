import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../db/local_auth_db.dart';
import '../models/student_id_card.dart';
import '../../features/dashboard_student/data/student_repository.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final StudentRepository _repository = StudentRepository();
  
  StudentIdCard? _childProfile;
  List<CourseGrade> _childGrades = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // For demo purposes, we link the parent to the first registered student ID (1001)
    // If 1001 isn't found, it falls back to the dynamic TIU demo profile automatically.
    final profile = await _repository.fetchStudentProfile('1001');
    final grades = await _repository.fetchMyGrades(profile.name);

    if (mounted) {
      setState(() {
        _childProfile = profile;
        _childGrades = grades;
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final authDb = LocalAuthDb(prefs);
    await authDb.clearSession();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
          : _buildCurrentView(),
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
                BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Notices'),
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

  Widget _buildSectionTopBar(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.mintGlow),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildChildProfileView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Child Overview'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Linked Student Profile', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 40, backgroundColor: AppTheme.mintGlow, child: Icon(Icons.person, color: AppTheme.darkCharcoal, size: 40)),
                      const SizedBox(height: 16),
                      Text(_childProfile?.name ?? 'Loading...', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Batch: ${_childProfile?.batch ?? ''}', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoTile('School', 'Tishk International University (TIU)'),
                _buildInfoTile('Department', _childProfile?.department ?? ''),
                _buildInfoTile('Major', _childProfile?.course ?? ''),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showMessage('Viewing child profile details.'),
                  child: const Text('VIEW FULL PROFILE'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Attendance'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
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
          ),
        ],
      ),
    );
  }

  Widget _buildGradesView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Academic Progress'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Grades Summary', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                // Dynamically mapping the shared gradebook
                ..._childGrades.map((gradeRecord) => _buildGradeRow(gradeRecord.courseName, gradeRecord.grade)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showMessage('Opening detailed grade report.'),
                  child: const Text('OPEN GRADE REPORT'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Notices'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Announcements', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildAnnouncementItem('Parent-teacher meeting regarding recent grades tomorrow at 5 PM.'),
                _buildAnnouncementItem('Your child has an upcoming science fair this week.'),
                _buildAnnouncementItem('Campus schedule updated for next Monday.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/announcements'),
                  child: const Text('VIEW ALL ANNOUNCEMENTS'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
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
    final isPending = grade.contains('Pending');
    
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(subject, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600))),
          Text(
            grade, 
            style: TextStyle(
              color: isPending ? Colors.orangeAccent : AppTheme.mintGlow, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
            )
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 14, height: 1.4)),
      ),
    );
  }
}