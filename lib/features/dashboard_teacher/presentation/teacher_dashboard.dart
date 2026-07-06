import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/models/student_id_card.dart';
import '../../../core/data/student_id_card_repository.dart';
import '../data/teacher_repository.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final TeacherRepository _repository = TeacherRepository();
  final StudentIdCardRepository _studentRepo = StudentIdCardRepository();
  
  List<StudentIdCard> _studentIdCards = [];
  List<SchoolClass> _todayClasses = [];
  List<StudentGrade> _gradeEntries = [];
  
  bool _isLoading = true;
  int _selectedIndex = 0;
  String _selectedCourse = 'Advanced Java OOP';
  String? _selectedStudentId;
  bool _sessionActive = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadGradesForCourse(String course) async {
    final savedGrades = await _repository.fetchSavedGradesForCourse(course);
    
    setState(() {
      _gradeEntries = savedGrades.isNotEmpty
          ? savedGrades
          : [
              StudentGrade(name: 'Ahmad Hassan', grade: '92'),
              StudentGrade(name: 'Shilan Azad', grade: '88'),
              StudentGrade(name: 'Rebwar Ali', grade: 'Pending...'),
            ];
    });
  }

  Future<void> _loadData() async {
    try {
      // Fetch both classes and students simultaneously from local storage
      final classes = await _repository.fetchTodayClasses();
      final students = await _studentRepo.fetchAllStudents();
      
      setState(() {
        _todayClasses = classes;
        _studentIdCards = students;
        
        if (_studentIdCards.isNotEmpty) {
          _selectedStudentId = _studentIdCards.first.id;
        }

        if (_todayClasses.isNotEmpty && !_todayClasses.any((c) => c.className == _selectedCourse)) {
          _selectedCourse = _todayClasses.first.className;
        }
        
        _isLoading = false;
      });

      // Load grades for the initially selected course
      await _loadGradesForCourse(_selectedCourse);
    } catch (e) {
      setState(() => _isLoading = false);
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
                  BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: 'Attendance'),
                  BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Grades'),
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
        return _buildAttendanceScannerView();
      case 2:
        return _buildGradingView();
      default:
        return _buildHomeView();
    }
  }

  Future<bool> _handleBackPressed() async {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false;
    }
    return true;
  }

  void _showPlaceholderMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleStudentGradeTap(StudentGrade student) {
    _openGradeEditor(student);
  }

  void _openGradeEditor(StudentGrade student) {
    final controller = TextEditingController(text: student.grade);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Edit Grade', style: TextStyle(color: AppTheme.pureWhite)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Grade',
            labelStyle: TextStyle(color: AppTheme.mintGlow),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.mintGlow)),
          ),
          TextButton(
            onPressed: () {
              final newGrade = controller.text.trim();
              if (newGrade.isNotEmpty) {
                setState(() {
                  student.grade = newGrade;
                });
                _showPlaceholderMessage('Updated ${student.name} grade.');
              }
              Navigator.of(context).pop();
            },
            child: const Text('SAVE', style: TextStyle(color: AppTheme.mintGlow)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitGrades() async {
    await _repository.saveGrades(_selectedCourse, _gradeEntries);
    _showPlaceholderMessage('Grades saved securely to device for $_selectedCourse.');
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
          expandedHeight: 120.0,
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
            title: const Text('Teacher Portal', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.deepTeal.withValues(alpha: 0.8), AppTheme.darkCharcoal],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.mintGlow.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: AppTheme.mintGlow, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prof. Abdulrahman', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Computer Education Dept.', style: TextStyle(color: AppTheme.mintGlow, fontSize: 14)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('My Classes Today', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._todayClasses.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.className, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c.time, style: const TextStyle(color: AppTheme.mintGlow)),
                              Text('${c.studentCount} Students', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceScannerView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Attendance'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Session Management', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Class', style: TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppTheme.darkCharcoal, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCourse,
                            items: _todayClasses
                                .map((c) => DropdownMenuItem(value: c.className, child: Text(c.className, style: const TextStyle(color: AppTheme.pureWhite))))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedCourse = value;
                              });
                              _showPlaceholderMessage('Active session switched to $value');
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Student ID Scan', style: TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppTheme.darkCharcoal, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedStudentId,
                            items: _studentIdCards
                                .map((student) => DropdownMenuItem(
                                      value: student.id,
                                      child: Text('${student.name} (${student.uniqueCode})', style: const TextStyle(color: AppTheme.pureWhite)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedStudentId = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _selectedStudentId == null
                            ? null
                            : () => context.push('/teacher/student-scan?id=$_selectedStudentId'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
                        child: const Text('SCAN STUDENT ID CARD', style: TextStyle(color: AppTheme.darkCharcoal)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push('/teacher/student-qr-scanner'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepTeal),
                        child: const Text('OPEN CAMERA QR SCANNER'),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.qr_code_2, color: AppTheme.darkCharcoal, size: 120),
                      ),
                      const SizedBox(height: 24),
                      Text('Active Session: $_selectedCourse', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _sessionActive
                            ? 'Display this QR code to the class. Syncs automatically with the Smart Attendance Manager.'
                            : 'The attendance session has ended. Tap the button to restart it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _sessionActive = !_sessionActive;
                          });
                          _showPlaceholderMessage(_sessionActive ? 'Attendance session started.' : 'Attendance session ended.');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: _sessionActive ? Colors.redAccent : AppTheme.deepTeal),
                        child: Text(_sessionActive ? 'END SESSION' : 'RESTART SESSION', style: const TextStyle(color: AppTheme.pureWhite)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/teacher/attendance'),
                        child: const Text('OPEN ATTENDANCE MANAGER'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.push('/teacher/student-scan?id=1001'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
                        child: const Text('SCAN STUDENT ID CARD', style: TextStyle(color: AppTheme.darkCharcoal)),
                      ),
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

  Widget _buildGradingView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Grade Entry'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Grade Entry', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Course', style: TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppTheme.darkCharcoal, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCourse,
                            items: const [
                              DropdownMenuItem(value: 'Advanced Java OOP', child: Text('Advanced Java OOP', style: TextStyle(color: AppTheme.pureWhite))),
                              DropdownMenuItem(value: 'Database Management Systems', child: Text('Database Management Systems', style: TextStyle(color: AppTheme.pureWhite))),
                              DropdownMenuItem(value: 'Software Engineering Principles', child: Text('Software Engineering Principles', style: TextStyle(color: AppTheme.pureWhite))),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedCourse = value);
                              _loadGradesForCourse(value);
                              _showPlaceholderMessage('Selected $value');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ..._gradeEntries.map((student) => _buildStudentGradeRow(student)),
                if (_gradeEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('No students available for this course yet.', style: TextStyle(color: AppTheme.pureWhite)),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitGrades,
                  child: const Text('SUBMIT GRADES'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/teacher/grade-entry?course=${Uri.encodeComponent(_selectedCourse)}'),
                  child: const Text('OPEN GRADE ENTRY'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGradeRow(StudentGrade student) {
    return GestureDetector(
      onTap: () => _handleStudentGradeTap(student),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(student.name, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(student.grade, style: TextStyle(color: student.grade.contains('Pending') ? Colors.orangeAccent : AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                const Icon(Icons.edit, color: AppTheme.pureWhite, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}