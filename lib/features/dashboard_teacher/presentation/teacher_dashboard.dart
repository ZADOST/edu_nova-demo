import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Edu Nova UI Components
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

// SQLite Database & Models (From abduattendancemanager)
import '../../../database/database_helper.dart';
import '../../../models/course.dart';
import '../../../models/student.dart';

// Live Functional Screens
import '../../../screens/live_attendance_page.dart';
import '../../../screens/attendance_records_page.dart';
import '../../../screens/manage_students_page.dart';

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
      // 1. Fetch real courses from SQLite
      final courses = await _dbHelper.getCourses();
      
      setState(() {
        _courses = courses;
        if (_courses.isNotEmpty && _selectedCourse == null) {
          _selectedCourse = _courses.first;
        }
      });

      // 2. Fetch real students for the selected course
      if (_selectedCourse != null) {
        await _loadStudentsForCourse(_selectedCourse!.id!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("DB Load Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentsForCourse(int courseId) async {
    try {
      final students = await _dbHelper.getStudentsInCourse(courseId);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Student Load Error: $e");
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
                    
                    // CRITICAL DB LOGIC: Create the session in SQLite
                    int sessionId = await _dbHelper.createAttendanceSession(
                      _selectedCourse!.id!,
                      selectedHours,
                    );
                    
                    if (mounted) {
                      // Navigate to the live functional camera scanner
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveAttendancePage(
                            sessionId: sessionId,
                            courseId: _selectedCourse!.id!,
                            totalHours: selectedHours,
                          ),
                        ),
                      ).then((_) => _loadData()); // Refresh data when returning
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
                  BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: 'Attendance'),
                  BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
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
        return _buildStudentsView();
      default:
        return _buildHomeView();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Active Courses', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
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
                      'No courses found in database.\nUse the Import/Manage section to add courses.',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Code: ${c.courseCode}', style: const TextStyle(color: AppTheme.mintGlow)),
                                const Icon(Icons.library_books, color: Colors.white54, size: 16),
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
                      const Text('Select Course Database', style: TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
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
                      
                      // THE LIVE SCANNER BUTTON
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
                      
                      // THE HISTORY BUTTON
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

  Widget _buildStudentsView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Student Directory'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                Text(_selectedCourse?.courseName ?? 'No Course Selected', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${_students.length} Enrolled Students', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 16)),
                const SizedBox(height: 24),
                
                if (_students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32.0),
                    child: Center(
                      child: Text('No students registered for this course.\nSelect a different course from the Attendance tab.', 
                        textAlign: TextAlign.center, 
                        style: TextStyle(color: Colors.white54, height: 1.5)
                      ),
                    ),
                  )
                else
                  ..._students.map((student) => GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.deepTeal,
                          child: Text(student.firstName[0], style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('ID: ${student.studentId} | Grade: ${student.grade}', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _selectedCourse == null ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageStudentsPage(courseId: _selectedCourse!.id!),
                      ),
                    ).then((_) => _loadStudentsForCourse(_selectedCourse!.id!));
                  },
                  icon: const Icon(Icons.edit_document),
                  label: const Text('MANAGE ENROLLMENT'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}