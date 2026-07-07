import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/course.dart';

class ManageStudentsPage extends StatefulWidget {
  final int courseId;

  const ManageStudentsPage({super.key, required this.courseId});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Course? _course;
  List<Student> _enrolledStudents = [];
  List<Student> _allStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch the specific subject
      final courses = await _dbHelper.getCourses();
      _course = courses.firstWhere((c) => c.id == widget.courseId);

      // Fetch the roster for this subject
      _enrolledStudents = await _dbHelper.getStudentsInCourse(widget.courseId);
      
      // Fetch the master directory to allow adding new students
      _allStudents = await _dbHelper.getAllStudents();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading roster: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unenrollStudent(Student student) async {
    final db = await _dbHelper.database;
    // Execute raw delete on the enrollments table
    await db.delete(
      'enrollments',
      where: 'student_id = ? AND course_id = ?',
      whereArgs: [student.studentId, widget.courseId],
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${student.firstName} removed from roster.')));
      _loadData();
    }
  }

  void _showAddStudentDialog() {
    // Filter out students who are already enrolled
    final unenrolledStudents = _allStudents.where((s) => !_enrolledStudents.any((enrolled) => enrolled.studentId == s.studentId)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Add Student to Subject', style: TextStyle(color: AppTheme.pureWhite)),
        content: SizedBox(
          width: double.maxFinite,
          child: unenrolledStudents.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('All registered students are already enrolled in this subject.', style: TextStyle(color: Colors.white70)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: unenrolledStudents.length,
                  itemBuilder: (context, index) {
                    final student = unenrolledStudents[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.deepTeal,
                        child: Text(student.firstName[0], style: const TextStyle(color: AppTheme.pureWhite)),
                      ),
                      title: Text(student.fullName, style: const TextStyle(color: AppTheme.pureWhite)),
                      subtitle: Text('ID: ${student.studentId} | Grade: ${student.grade}', style: const TextStyle(color: AppTheme.mintGlow)),
                      trailing: const Icon(Icons.add_circle_outline, color: AppTheme.mintGlow),
                      onTap: () async {
                        Navigator.pop(context);
                        await _dbHelper.enrollStudent(student.studentId, widget.courseId);
                        _loadData();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${student.firstName} added to roster.')));
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Roster Management', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
        : SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_course?.courseName ?? 'Unknown Subject', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Subject Code: ${_course?.courseCode ?? ''}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 14)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Enrolled: ${_enrolledStudents.length}', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _showAddStudentDialog,
                            icon: const Icon(Icons.person_add, color: AppTheme.darkCharcoal, size: 18),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow, visualDensity: VisualDensity.compact),
                            label: const Text('ADD', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: _enrolledStudents.length,
                    itemBuilder: (context, index) {
                      final student = _enrolledStudents[index];
                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.darkCharcoal,
                              child: Text(student.firstName[0], style: const TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('ID: ${student.studentId} | Grade: ${student.grade}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              tooltip: 'Remove from Roster',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppTheme.darkCharcoal,
                                    title: const Text('Confirm Removal', style: TextStyle(color: AppTheme.pureWhite)),
                                    content: Text('Are you sure you want to remove ${student.firstName} from this subject?', style: const TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppTheme.mintGlow))),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _unenrollStudent(student);
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        child: const Text('REMOVE', style: TextStyle(color: AppTheme.pureWhite)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}