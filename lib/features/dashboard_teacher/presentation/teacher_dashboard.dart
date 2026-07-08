import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Edu Nova UI Components
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

// SQLite Database & Models
import '../../../database/database_helper.dart';
import '../../../models/course.dart';
import '../../../models/student.dart';

// Screens
import '../../../screens/live_attendance_page.dart';
import '../../../screens/attendance_records_page.dart';
import '../../../core/screens/profile_screen.dart';
import '../../../core/screens/settings_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Course> _courses = [];
  Course? _selectedCourse;
  List<Student> _students = [];
  Map<String, String> _studentGrades = {};
  
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
      final courses = await _dbHelper.getCourses();
      
      if (mounted) {
        setState(() {
          _courses = courses;
          if (_courses.isNotEmpty && _selectedCourse == null) {
            _selectedCourse = _courses.first;
          }
        });
      }

      if (_selectedCourse != null) {
        await _loadStudentsForCourse(_selectedCourse!.id!);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("DB Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentsForCourse(int courseId) async {
    try {
      final students = await _dbHelper.getStudentsInCourse(courseId);
      
      Map<String, String> grades = {};
      for (var student in students) {
        grades[student.studentId] = await _dbHelper.getStudentGrade(student.studentId, courseId);
      }

      if (mounted) {
        setState(() {
          _students = students;
          _studentGrades = grades;
          _isLoading = false;
        });
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

  void _showHourSelectionDialog() {
    int selectedHours = 1;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.darkCharcoal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.mintGlow, width: 1),
              ),
              title: const Text(
                'Select Session Hours',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.pureWhite),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How many hours for ${_selectedCourse?.courseName ?? "this session"}?',
                    style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    children: [1, 2, 3, 4].map((hour) {
                      return ChoiceChip(
                        label: Text('$hour', style: TextStyle(color: selectedHours == hour ? AppTheme.darkCharcoal : AppTheme.pureWhite)),
                        selected: selectedHours == hour,
                        onSelected: (selected) {
                          setDialogState(() {
                            selectedHours = hour;
                          });
                        },
                        selectedColor: AppTheme.mintGlow,
                        backgroundColor: AppTheme.deepTeal.withValues(alpha: 0.5),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    
                    int sessionId = await _dbHelper.createAttendanceSession(
                      _selectedCourse!.id!,
                      selectedHours,
                    );
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveAttendancePage(
                            sessionId: sessionId,
                            courseId: _selectedCourse!.id!,
                            totalHours: selectedHours,
                          ),
                        ),
                      ).then((_) => _loadData());
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
                  child: const Text('START SESSION', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openGradeEditor(Student student) {
    String currentGrade = _studentGrades[student.studentId] ?? '';
    final controller = TextEditingController(text: currentGrade == 'Pending...' ? '' : currentGrade);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: Text('Edit Grade: ${student.firstName}', style: const TextStyle(color: AppTheme.pureWhite)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.pureWhite),
          decoration: const InputDecoration(
            labelText: 'Academic Grade (e.g. A, 95)',
            labelStyle: TextStyle(color: AppTheme.mintGlow),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newGrade = controller.text.trim();
              if (newGrade.isNotEmpty) {
                Navigator.of(context).pop();
                await _dbHelper.updateGrade(student.studentId, _selectedCourse!.id!, newGrade);
                _loadStudentsForCourse(_selectedCourse!.id!);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grade updated for ${student.firstName}')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            child: const Text('SAVE', style: TextStyle(color: AppTheme.darkCharcoal)),
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
          margin: const EdgeInsets.all(16),
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
                  BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: 'Attendance'),
                  BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Grades'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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
      case 0: return _buildHomeView();
      case 1: return _buildAttendanceScannerView();
      case 2: return _buildGradingView();
      case 3: return const ProfileScreen(); // Re-integrated from your previous UI
      case 4: return const SettingsScreen(); // Re-integrated from your previous UI
      default: return _buildHomeView();
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Active Classes', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.mintGlow),
                    onPressed: _loadData,
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              if (_courses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.deepTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.mintGlow.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      'No courses assigned to you yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.pureWhite, height: 1.5),
                    ),
                  ),
                )
              else
                ..._courses.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.courseName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Subject Code: ${c.courseCode}', style: const TextStyle(color: AppTheme.mintGlow)),
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
          _buildSectionTopBar('Live Attendance'),
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
                      const Text('Select Subject', style: TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppTheme.darkCharcoal, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Course>(
                            isExpanded: true,
                            value: _selectedCourse,
                            dropdownColor: AppTheme.darkCharcoal,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.mintGlow),
                            items: _courses
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.courseName, style: const TextStyle(color: AppTheme.pureWhite)),
                                    ))
                                .toList(),
                            onChanged: (Course? value) {
                              if (value == null) return;
                              setState(() {
                                _selectedCourse = value;
                                _isLoading = true;
                              });
                              _loadStudentsForCourse(value.id!);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _selectedCourse == null ? null : _showHourSelectionDialog,
                        icon: const Icon(Icons.camera_alt, color: AppTheme.darkCharcoal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mintGlow,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        label: const Text('START LIVE SCANNER', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AttendanceRecordsPage()),
                          );
                        },
                        icon: const Icon(Icons.history, color: AppTheme.pureWhite),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepTeal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        label: const Text('ATTENDANCE RECORDS', style: TextStyle(color: AppTheme.pureWhite)),
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
                const Text('Academic Ledger', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Subject Ledger', style: TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppTheme.darkCharcoal, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Course>(
                            isExpanded: true,
                            dropdownColor: AppTheme.darkCharcoal,
                            value: _selectedCourse,
                            items: _courses.map((c) => DropdownMenuItem(value: c, child: Text(c.courseName, style: const TextStyle(color: AppTheme.pureWhite)))).toList(),
                            onChanged: (Course? value) {
                              if (value == null) return;
                              setState(() {
                                _selectedCourse = value;
                                _isLoading = true;
                              });
                              _loadStudentsForCourse(value.id!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                if (_students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('No students enrolled in this subject yet.', style: TextStyle(color: AppTheme.pureWhite)),
                  )
                else
                  ..._students.map((student) {
                    String currentGrade = _studentGrades[student.studentId] ?? 'Pending...';
                    return GestureDetector(
                      onTap: () => _openGradeEditor(student),
                      child: GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(student.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600))),
                            Row(
                              children: [
                                Text(
                                  currentGrade, 
                                  style: TextStyle(
                                    color: currentGrade.contains('Pending') ? Colors.orangeAccent : AppTheme.mintGlow, 
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.edit, color: AppTheme.pureWhite, size: 18),
                              ],
                            ),
                          ],
                        ),
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