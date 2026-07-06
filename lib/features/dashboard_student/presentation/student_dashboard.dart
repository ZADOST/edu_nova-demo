import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/models/student_id_card.dart';
import 'widgets/course_glass_card.dart';
import '../data/student_repository.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final StudentRepository _repository = StudentRepository();
  
  StudentIdCard? _profile;
  List<CourseGrade> _myGrades = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final authDb = LocalAuthDb(prefs);
    
    // Fallback to U_001 if the login ID isn't found
    final currentUserId = authDb.userRole == 'student' ? '1001' : 'U_001'; 
    
    final profile = await _repository.fetchStudentProfile(currentUserId);
    final grades = await _repository.fetchMyGrades(profile.name);

    if (mounted) {
      setState(() {
        _profile = profile;
        _myGrades = grades;
        _isLoading = false;
      });
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
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
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
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
                  BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Grades'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeView();
      case 1:
        return _buildScheduleView();
      case 2:
        return _buildGradesView();
      case 3:
        return _buildProfileView();
      default:
        return _buildHomeView();
    }
  }

  Future<bool> _handleBackPressed() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
    return true;
  }

  Widget _buildSectionTopBar(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
            onPressed: () => setState(() => _selectedIndex = 0),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    final firstName = _profile?.name.split(' ').first ?? 'Student';
    // Friendly override for your specific demo profile
    final displayGreeting = _profile?.name.contains('Shazad') == true ? 'ZAD' : firstName;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220.0,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.darkCharcoal,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month, color: AppTheme.mintGlow),
              onPressed: () => context.push('/timetable'),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: AppTheme.mintGlow),
              onPressed: () => context.push('/profile'),
            ),
            IconButton(
              icon: const Icon(Icons.notifications, color: AppTheme.mintGlow),
              onPressed: () => context.push('/notifications'),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: AppTheme.mintGlow),
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.mintGlow),
              onPressed: () => _handleLogout(context),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: Text(
              'Welcome back, $displayGreeting',
              style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.deepTeal.withValues(alpha: 0.8),
                    AppTheme.darkCharcoal,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    top: -50,
                    child: CircleAvatar(radius: 100, backgroundColor: AppTheme.mintGlow.withValues(alpha: 0.05)),
                  ),
                  Positioned(
                    left: 24,
                    top: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Spring Semester 2026', style: TextStyle(color: AppTheme.mintGlow, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        GlassContainer(
                          blur: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          borderRadius: BorderRadius.circular(12),
                          child: const Text('GPA: 3.85', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(onTap: () => setState(() => _selectedIndex = 1), child: _buildQuickAction(Icons.qr_code_scanner, 'Attendance')),
                  GestureDetector(onTap: () => setState(() => _selectedIndex = 2), child: _buildQuickAction(Icons.assignment, 'Grades')),
                  GestureDetector(onTap: () => setState(() => _selectedIndex = 2), child: _buildQuickAction(Icons.receipt_long, 'Transcript')),
                  GestureDetector(onTap: () => setState(() => _selectedIndex = 3), child: _buildQuickAction(Icons.person, 'Profile')),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Today\'s Courses', style: TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const CourseGlassCard(courseName: 'Advanced Java OOP', instructor: 'Dr. Alan Turing', time: '10:00 AM - 11:30 AM', progress: 0.75),
              const CourseGlassCard(courseName: 'Database Management Systems', instructor: 'Prof. Grace Hopper', time: '12:00 PM - 01:30 PM', progress: 0.40),
              const CourseGlassCard(courseName: 'Software Engineering Principles', instructor: 'Dr. Ada Lovelace', time: '02:00 PM - 03:30 PM', progress: 0.90),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Schedule'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Academic Schedule', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2, color: AppTheme.mintGlow, size: 64),
                      const SizedBox(height: 16),
                      const Text('Smart Attendance Manager', style: TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Scan the professor\'s classroom QR code to log your attendance instantly.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: () => context.push('/student/attendance'), child: const Text('OPEN SCANNER')),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Upcoming Classes', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const CourseGlassCard(courseName: 'Advanced Java OOP', instructor: 'Dr. Alan Turing', time: '10:00 AM - 11:30 AM', progress: 0.0),
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
          _buildSectionTopBar('Grades'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Academic Transcript', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                // Render dynamically fetched grades
                ..._myGrades.map((gradeRecord) => _buildGradeRow(gradeRecord.courseName, gradeRecord.grade)),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeRow(String course, String grade) {
    // Generate a mock percentage string for visual completion unless it's pending
    final isPending = grade.contains('Pending');
    final displayPercentage = isPending ? 'N/A' : 'Graded';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(course, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                grade, 
                style: TextStyle(
                  color: isPending ? Colors.orangeAccent : AppTheme.mintGlow, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                )
              ),
              Text(displayPercentage, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.5), fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Profile'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Student Profile', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(radius: 40, backgroundColor: AppTheme.mintGlow.withValues(alpha: 0.2), child: const Icon(Icons.person, size: 40, color: AppTheme.mintGlow)),
                      const SizedBox(height: 16),
                      Text(_profile?.name ?? 'Loading...', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Student ID: ${_profile?.uniqueCode ?? ''}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Academic Details', style: TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildProfileDetailRow('University', 'Tishk International University (TIU)'),
                      const Divider(color: Colors.white24, height: 24),
                      _buildProfileDetailRow('Department', _profile?.department ?? ''),
                      const Divider(color: Colors.white24, height: 24),
                      _buildProfileDetailRow('Major Course', _profile?.course ?? ''),
                      const Divider(color: Colors.white24, height: 24),
                      _buildProfileDetailRow('Batch Group', _profile?.batch ?? ''),
                      const Divider(color: Colors.white24, height: 24),
                      _buildProfileDetailRow('Organization', 'KSTIU Membership'),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.deepTeal.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.mintGlow.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(icon, color: AppTheme.mintGlow, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}