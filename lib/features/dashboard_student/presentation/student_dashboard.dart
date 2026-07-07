import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

import '../../../database/database_helper.dart';
import '../../../models/student.dart';
import '../../../models/course.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Student? _profile;
  List<Map<String, dynamic>> _myAcademics = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Identify the logged-in student (For demo, we grab the first student in the DB)
      final allStudents = await _dbHelper.getAllStudents();
      
      if (allStudents.isNotEmpty) {
        _profile = allStudents.first;
        
        // 2. Fetch enrolled subjects and calculate real-time grades & latency
        final db = await _dbHelper.database;
        var enrollments = await db.rawQuery('''
          SELECT c.* FROM courses c 
          INNER JOIN enrollments e ON c.id = e.course_id 
          WHERE e.student_id = ?
        ''', [_profile!.studentId]);
        
        List<Map<String, dynamic>> academicsList = [];
        
        for (var row in enrollments) {
          Course subject = Course.fromMap(row);
          String grade = await _dbHelper.getStudentGrade(_profile!.studentId, subject.id!);
          double latency = await _dbHelper.getStudentLatency(_profile!.studentId, subject.id!);
          
          academicsList.add({
            'subject': subject,
            'grade': grade,
            'latency': latency,
          });
        }
        
        if (mounted) {
          setState(() {
            _myAcademics = academicsList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Student Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
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
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        return true;
      },
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
                onTap: (index) => setState(() => _selectedIndex = index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Subjects'),
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
    if (_profile == null) return _buildEmptyStateView();
    
    switch (_selectedIndex) {
      case 0: return _buildHomeView();
      case 1: return _buildScheduleView();
      case 2: return _buildGradesView();
      case 3: return _buildProfileView();
      default: return _buildHomeView();
    }
  }

  Widget _buildEmptyStateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, color: AppTheme.mintGlow, size: 80),
            const SizedBox(height: 24),
            const Text('No Student Profile Found', style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Please log in as the Principal and register a student in the Master Directory first.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
              child: const Text('RETURN TO LOGIN', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220.0,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.darkCharcoal,
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.logout, color: AppTheme.mintGlow), onPressed: () => _handleLogout(context)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: Text(
              'Welcome back, ${_profile!.firstName}',
              style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.deepTeal.withValues(alpha: 0.8), AppTheme.darkCharcoal],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 24,
                    top: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Grade Level: ${_profile!.grade}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        GlassContainer(
                          blur: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          borderRadius: BorderRadius.circular(12),
                          child: Text('${_myAcademics.length} Enrolled Subjects', style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
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
                  GestureDetector(onTap: () => setState(() => _selectedIndex = 1), child: _buildQuickAction(Icons.menu_book, 'Subjects')),
                  GestureDetector(onTap: () => setState(() => _selectedIndex = 2), child: _buildQuickAction(Icons.assignment, 'Grades')),
                  GestureDetector(onTap: () => setState(() => _selectedIndex = 2), child: _buildQuickAction(Icons.insights, 'Attendance')),
                  GestureDetector(onTap: () => setState(() => _selectedIndex = 3), child: _buildQuickAction(Icons.person, 'Profile')),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Academic Overview', style: TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (_myAcademics.isEmpty)
                const Text('You have not been assigned to any subjects yet.', style: TextStyle(color: Colors.white60))
              else
                ..._myAcademics.map((academic) {
                  Course subject = academic['subject'];
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(subject.courseName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                        const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
                      ],
                    ),
                  );
                }),
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
          _buildSectionTopBar('My Subjects'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                if (_myAcademics.isEmpty)
                  const Text('No subjects assigned.', style: TextStyle(color: Colors.white60))
                else
                  ..._myAcademics.map((academic) {
                    Course subject = academic['subject'];
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject.courseName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Code: ${subject.courseCode}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 12)),
                          const Divider(color: Colors.white24, height: 24),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.white60, size: 16),
                              const SizedBox(width: 8),
                              Text(subject.teacherId != null ? 'Assigned Teacher' : 'Teacher Pending', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          )
                        ],
                      ),
                    );
                  }),
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
                if (_myAcademics.isEmpty)
                  const Text('No academic data available.', style: TextStyle(color: Colors.white60))
                else
                  ..._myAcademics.map((academic) {
                    Course subject = academic['subject'];
                    String grade = academic['grade'];
                    double latency = academic['latency'];
                    
                    Color latencyColor = latency >= 80 ? Colors.greenAccent : (latency >= 50 ? Colors.orangeAccent : Colors.redAccent);
                    
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject.courseName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Current Grade', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(grade, style: TextStyle(color: grade.contains('Pending') ? Colors.orangeAccent : Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Attendance Rate', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('${latency.toStringAsFixed(0)}%', style: TextStyle(color: latencyColor, fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 80),
              ],
            ),
          ),
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
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(radius: 40, backgroundColor: AppTheme.mintGlow.withValues(alpha: 0.2), child: const Icon(Icons.person, size: 40, color: AppTheme.mintGlow)),
                      const SizedBox(height: 16),
                      Text(_profile!.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Student ID: ${_profile!.studentId}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 14)),
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
                      _buildProfileDetailRow('Grade Level', _profile!.grade),
                      const Divider(color: Colors.white24, height: 24),
                      _buildProfileDetailRow('Enrolled Subjects', '${_myAcademics.length}'),
                      const Divider(color: Colors.white24, height: 24),
                      _buildProfileDetailRow('System Status', 'Active'),
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
        SizedBox(width: 120, child: Text(label, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 13))),
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