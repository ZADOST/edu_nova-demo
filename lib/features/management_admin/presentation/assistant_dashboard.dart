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

class PrincipalAssistantDashboard extends StatefulWidget {
  const PrincipalAssistantDashboard({super.key});

  @override
  State<PrincipalAssistantDashboard> createState() => _PrincipalAssistantDashboardState();
}

class _PrincipalAssistantDashboardState extends State<PrincipalAssistantDashboard> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  int _totalStudents = 0;
  int _totalSubjects = 0;
  int _totalTeachers = 0;
  
  List<Course> _subjects = [];
  Course? _selectedMonitoringSubject;
  List<Student> _enrolledStudents = [];
  Map<String, double> _studentLatencies = {};
  Map<String, String> _studentGrades = {};
  List<Map<String, dynamic>> _myRequests = [];

  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSystemData();
  }

  Future<void> _loadSystemData() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _dbHelper.getCourses();
      final students = await _dbHelper.getAllStudents();
      final teachers = await _dbHelper.getTeachers();
      final requests = await _dbHelper.getRequestsBySender('Assistant Principal');
      
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _totalSubjects = subjects.length;
          _totalStudents = students.length;
          _totalTeachers = teachers.length;
          _myRequests = requests;
          
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
      debugPrint("Assistant Stats Load Error: $e");
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

  // Escalation Logic: Generating a request for the Principal
  void _showSubmitRequestDialog(Student student, String currentGrade) {
    final gradeCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: Text('Request Modification: ${student.firstName}', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Grade: $currentGrade', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: gradeCtrl,
              style: const TextStyle(color: AppTheme.pureWhite),
              decoration: const InputDecoration(labelText: 'Proposed Grade', labelStyle: TextStyle(color: AppTheme.mintGlow)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: AppTheme.pureWhite),
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason for Request', labelStyle: TextStyle(color: AppTheme.mintGlow)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              if (gradeCtrl.text.isNotEmpty && reasonCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                
                // Submit to queue instead of direct database update
                await _dbHelper.submitAdminRequest(
                  requestedBy: 'Assistant Principal',
                  actionType: 'Grade Update',
                  targetStudentId: student.studentId,
                  targetCourseId: _selectedMonitoringSubject!.id!,
                  proposedValue: gradeCtrl.text,
                  reason: reasonCtrl.text,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted to Principal for approval.')));
                _loadSystemData(); // Refresh the requests list
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            child: const Text('SUBMIT REQUEST', style: TextStyle(color: AppTheme.darkCharcoal)),
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
                  BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'Monitoring'),
                  BottomNavigationBarItem(icon: Icon(Icons.outbox), label: 'My Requests'),
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
      case 1: return _buildMonitoringView();
      case 2: return _buildRequestsView();
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
            title: const Text('Assistant Principal', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
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
              const SizedBox(height: 32),
              const Text('Notice: System access is currently restricted to Read-Only Analytics. To make structural changes, submit an escalation request to the Principal via the Monitoring tab.', style: TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic, height: 1.5)),
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
                            icon: const Icon(Icons.outbox, color: Colors.orangeAccent),
                            tooltip: 'Request Modification',
                            onPressed: () => _showSubmitRequestDialog(student, grade),
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

  Widget _buildRequestsView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('My Escalations'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const Text('Pending & Past Requests', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                if (_myRequests.isEmpty)
                  const Text('You have no submitted requests.', style: TextStyle(color: Colors.white60))
                else
                  ..._myRequests.map((req) {
                    Color statusColor = req['status'] == 'Pending' ? Colors.orangeAccent : 
                                        req['status'] == 'Approved' ? Colors.green : Colors.redAccent;
                                        
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(req['action_type'], style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text(req['status'], style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Student ID: ${req['target_student_id']}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 12)),
                          Text('Proposed Change: ${req['proposed_value']}', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                          const Divider(color: Colors.white24),
                          Text('Reason: ${req['reason']}', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7), fontSize: 12, fontStyle: FontStyle.italic)),
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