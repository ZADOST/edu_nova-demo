import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../db/local_auth_db.dart';

import '../../database/database_helper.dart';
import '../../models/student.dart';
import '../../models/course.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Student? _child;
  List<Map<String, dynamic>> _childAcademics = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allStudents = await _dbHelper.getAllStudents();
      
      if (allStudents.isNotEmpty) {
        _child = allStudents.first; // Simulating linked child
        
        final db = await _dbHelper.database;
        var enrollments = await db.rawQuery('''
          SELECT c.* FROM courses c 
          INNER JOIN enrollments e ON c.id = e.course_id 
          WHERE e.student_id = ?
        ''', [_child!.studentId]);
        
        List<Map<String, dynamic>> academicsList = [];
        
        for (var row in enrollments) {
          Course subject = Course.fromMap(row);
          String grade = await _dbHelper.getStudentGrade(_child!.studentId, subject.id!);
          double latency = await _dbHelper.getStudentLatency(_child!.studentId, subject.id!);
          
          academicsList.add({
            'subject': subject,
            'grade': grade,
            'latency': latency,
          });
        }
        
        if (mounted) {
          setState(() {
            _childAcademics = academicsList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Parent Load Error: $e");
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
                BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Attendance'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Grades'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_child == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom, color: AppTheme.mintGlow, size: 80),
              const SizedBox(height: 24),
              const Text('No Linked Student', style: TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Your account is not linked to an active student. Please contact the Principal.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
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

    switch (_selectedIndex) {
      case 1: return _buildAttendanceView();
      case 2: return _buildGradesView();
      default: return _buildChildProfileView();
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
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 40, backgroundColor: AppTheme.mintGlow, child: Icon(Icons.person, color: AppTheme.darkCharcoal, size: 40)),
                      const SizedBox(height: 16),
                      Text(_child!.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Grade: ${_child!.grade}', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoTile('School', 'Local K-12 Institution'),
                _buildInfoTile('Student ID', _child!.studentId),
                _buildInfoTile('Enrolled Subjects', '${_childAcademics.length}'),
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
                const Text('Latency by Subject', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_childAcademics.isEmpty)
                  const Text('No attendance data available.', style: TextStyle(color: Colors.white60))
                else
                  ..._childAcademics.map((academic) {
                    Course subject = academic['subject'];
                    double latency = academic['latency'];
                    Color latencyColor = latency >= 80 ? Colors.greenAccent : (latency >= 50 ? Colors.orangeAccent : Colors.redAccent);
                    
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(subject.courseName, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                          Text('${latency.toStringAsFixed(0)}%', style: TextStyle(color: latencyColor, fontWeight: FontWeight.bold, fontSize: 18)),
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
                const Text('Subject Grades', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_childAcademics.isEmpty)
                  const Text('No grade data available.', style: TextStyle(color: Colors.white60))
                else
                  ..._childAcademics.map((academic) {
                    Course subject = academic['subject'];
                    String grade = academic['grade'];
                    
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(subject.courseName, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                          Text(grade, style: TextStyle(color: grade.contains('Pending') ? Colors.orangeAccent : Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18)),
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

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}