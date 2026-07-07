import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

import '../../../database/database_helper.dart';
import '../../../models/course.dart';
import '../../../models/student.dart';
import '../../../screens/manage_students_page.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  int _totalStudents = 0;
  int _totalSubjects = 0;
  int _totalTeachers = 0;
  
  List<Course> _subjects = [];
  List<Map<String, dynamic>> _teachers = [];
  Course? _selectedMonitoringSubject;
  List<Student> _enrolledStudents = [];
  Map<String, double> _studentLatencies = {};
  Map<String, String> _studentGrades = {};

  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _seedInitialStaff();
    _loadSystemData();
  }

  // Ensures we have teachers to assign if the database is fresh
  Future<void> _seedInitialStaff() async {
    final existing = await _dbHelper.getTeachers();
    if (existing.isEmpty) {
      await _dbHelper.addTeacher('T-001', 'Dr. Alan Turing', 'Mathematics');
      await _dbHelper.addTeacher('T-002', 'Prof. Marie Curie', 'Chemistry');
      await _dbHelper.addTeacher('T-003', 'Dr. Rosalind Franklin', 'Biology');
    }
  }

  Future<void> _loadSystemData() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _dbHelper.getCourses();
      final students = await _dbHelper.getAllStudents();
      final teachers = await _dbHelper.getTeachers();
      
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _teachers = teachers;
          _totalSubjects = subjects.length;
          _totalStudents = students.length;
          _totalTeachers = teachers.length;
          
          if (_subjects.isNotEmpty && _selectedMonitoringSubject == null) {
            _selectedMonitoringSubject = _subjects.first;
          }
          _isLoading = false;
        });
      }

      if (_selectedMonitoringSubject != null) {
        await _loadMonitoringData(_selectedMonitoringSubject!.id!);
      }
    } catch (e) {
      debugPrint("Admin Stats Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMonitoringData(int subjectId) async {
    final students = await _dbHelper.getStudentsInCourse(subjectId);
    Map<String, double> latencies = {};
    Map<String, String> grades = {};

    for (var s in students) {
      latencies[s.studentId] = await _dbHelper.getStudentLatency(s.studentId, subjectId);
      grades[s.studentId] = await _dbHelper.getStudentGrade(s.studentId, subjectId);
    }

    setState(() {
      _enrolledStudents = students;
      _studentLatencies = latencies;
      _studentGrades = grades;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final authDb = LocalAuthDb(prefs);
    await authDb.clearSession();
    if (context.mounted) context.go('/login');
  }

  void _showAddSubjectDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Create New Subject', style: TextStyle(color: AppTheme.pureWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.pureWhite),
              decoration: const InputDecoration(labelText: 'Subject Name (e.g. Biology)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
            ),
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color: AppTheme.pureWhite),
              decoration: const InputDecoration(labelText: 'Subject Code (e.g. BIO-101)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && codeCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _dbHelper.addCourse(nameCtrl.text, codeCtrl.text);
                _loadSystemData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            child: const Text('CREATE SUBJECT', style: TextStyle(color: AppTheme.darkCharcoal)),
          ),
        ],
      ),
    );
  }

  void _showAssignTeacherDialog(Course subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: Text('Assign Teacher to ${subject.courseName}', style: const TextStyle(color: AppTheme.pureWhite)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _teachers.length,
            itemBuilder: (context, index) {
              var teacher = _teachers[index];
              return ListTile(
                title: Text(teacher['full_name'], style: const TextStyle(color: AppTheme.pureWhite)),
                subtitle: Text(teacher['department'], style: const TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.person_add, color: AppTheme.mintGlow),
                onTap: () async {
                  Navigator.pop(context);
                  await _dbHelper.assignTeacherToCourse(subject.id!, teacher['teacher_id']);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${teacher['full_name']} assigned to ${subject.courseName}')));
                  _loadSystemData();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showUpdateGradeDialog(Student student) {
    final gradeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: Text('Update Grade: ${student.firstName}', style: const TextStyle(color: AppTheme.pureWhite)),
        content: TextField(
          controller: gradeCtrl,
          style: const TextStyle(color: AppTheme.pureWhite),
          decoration: const InputDecoration(labelText: 'New Grade (e.g. A, 95%)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              if (gradeCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _dbHelper.updateGrade(student.studentId, _selectedMonitoringSubject!.id!, gradeCtrl.text);
                _loadMonitoringData(_selectedMonitoringSubject!.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            child: const Text('SAVE GRADE', style: TextStyle(color: AppTheme.darkCharcoal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) { setState(() => _selectedIndex = 0); return false; }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkCharcoal,
        body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow)) : _buildCurrentView(),
        extendBody: true,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: AppTheme.darkCharcoal.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))],
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
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
                  BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Curriculum'),
                  BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'Monitoring'),
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
      case 0: return _buildOverviewView();
      case 1: return _buildCurriculumView();
      case 2: return _buildMonitoringView();
      default: return _buildOverviewView();
    }
  }

  Widget _buildSectionTopBar(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow), onPressed: () => setState(() => _selectedIndex = 0)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOverviewView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false, pinned: true, backgroundColor: AppTheme.darkCharcoal, elevation: 0,
          actions: [IconButton(icon: const Icon(Icons.logout, color: AppTheme.mintGlow), onPressed: () => _handleLogout(context))],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: const Text('Master Principal Dashboard', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
            background: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.deepTeal.withValues(alpha: 0.8), AppTheme.darkCharcoal]))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(child: _buildStatCard('$_totalStudents', 'Total Students', Icons.people_alt)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('$_totalTeachers', 'Total Teachers', Icons.badge)),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatCard('$_totalSubjects', 'Active School Subjects', Icons.library_books),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.mintGlow, size: 28),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 32, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCurriculumView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Curriculum Setup'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddSubjectDialog,
                  icon: const Icon(Icons.add, color: AppTheme.darkCharcoal),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow, padding: const EdgeInsets.symmetric(vertical: 16)),
                  label: const Text('CREATE NEW SUBJECT', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                ..._subjects.map((subject) => GlassContainer(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject.courseName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Code: ${subject.courseCode}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 12)),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showAssignTeacherDialog(subject),
                            icon: const Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
                            label: const Text('Assign Teacher', style: TextStyle(color: Colors.white70)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ManageStudentsPage(courseId: subject.id!)))
                              .then((_) => _loadSystemData());
                            },
                            icon: const Icon(Icons.people, color: Colors.orangeAccent),
                            label: const Text('Manage Roster', style: TextStyle(color: Colors.white70)),
                          ),
                        ],
                      )
                    ],
                  ),
                )),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Academic Monitoring'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const Text('Select Subject to Monitor', style: TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppTheme.darkCharcoal, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Course>(
                      isExpanded: true,
                      dropdownColor: AppTheme.darkCharcoal,
                      value: _selectedMonitoringSubject,
                      items: _subjects.map((c) => DropdownMenuItem(value: c, child: Text(c.courseName, style: const TextStyle(color: AppTheme.pureWhite)))).toList(),
                      onChanged: (Course? value) {
                        if (value == null) return;
                        setState(() => _selectedMonitoringSubject = value);
                        _loadMonitoringData(value.id!);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_enrolledStudents.isEmpty)
                  const Text('No students enrolled in this subject.', style: TextStyle(color: Colors.white60))
                else
                  ..._enrolledStudents.map((student) {
                    double latency = _studentLatencies[student.studentId] ?? 100.0;
                    String grade = _studentGrades[student.studentId] ?? 'Pending';
                    Color latencyColor = latency >= 80 ? Colors.green : (latency >= 50 ? Colors.orange : Colors.red);
                    
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: AppTheme.darkCharcoal, child: Text(student.firstName[0], style: const TextStyle(color: AppTheme.mintGlow))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Attendance: ', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 12)),
                                    Text('${latency.toStringAsFixed(0)}%', style: TextStyle(color: latencyColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('Grade: ', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 12)),
                                    Text(grade, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_document, color: AppTheme.mintGlow),
                            onPressed: () => _showUpdateGradeDialog(student),
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
}