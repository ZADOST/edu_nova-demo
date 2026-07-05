import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../data/teacher_repository.dart';

class TeacherGradeEntryScreen extends StatefulWidget {
  final String initialCourse;

  const TeacherGradeEntryScreen({
    super.key,
    this.initialCourse = 'Advanced Java OOP',
  });

  @override
  State<TeacherGradeEntryScreen> createState() => _TeacherGradeEntryScreenState();
}

class _TeacherGradeEntryScreenState extends State<TeacherGradeEntryScreen> {
  final TeacherRepository _repository = TeacherRepository();
  // removed unused _todayClasses field
  final List<StudentGrade> _students = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedCourse = 'Advanced Java OOP';

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.initialCourse;
    _loadClasses();
    _loadStudentsForCourse(_selectedCourse);
  }

  Future<void> _loadClasses() async {
    try {
      await _repository.fetchTodayClasses();
      setState(() {
        // classes fetched (not stored here) — update loading state
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _loadStudentsForCourse(String course) {
    final saved = _repository.fetchSavedGradesForCourse(course);
    if (saved.isNotEmpty) {
      _students
        ..clear()
        ..addAll(saved);
      return;
    }

    final mockStudents = <StudentGrade>[
      StudentGrade(name: 'Ahmad Hassan', grade: 'A'),
      StudentGrade(name: 'Shilan Azad', grade: 'B+'),
      StudentGrade(name: 'Rebwar Ali', grade: 'A-'),
    ];
    _students
      ..clear()
      ..addAll(mockStudents);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              setState(() {
                student.grade = controller.text.trim().isEmpty ? student.grade : controller.text.trim();
              });
              Navigator.of(context).pop();
              _showMessage('Updated ${student.name} grade.');
            },
            child: const Text('SAVE', style: TextStyle(color: AppTheme.mintGlow)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAllGrades() async {
    setState(() => _isSaving = true);
    await _repository.saveGrades(
      _selectedCourse,
      _students.map((student) => StudentGrade(name: student.name, grade: student.grade)).toList(),
    );
    setState(() => _isSaving = false);
    _showMessage('Saved grades for $_selectedCourse');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Grade Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => context.go('/teacher'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const Text('Teacher Grade Entry', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
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
                              setState(() {
                                _selectedCourse = value;
                                _loadStudentsForCourse(value);
                              });
                              _showMessage('Selected $value');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Students', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._students.map((student) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.name, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('Grade: ${student.grade}', style: TextStyle(color: AppTheme.mintGlow)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.mintGlow),
                              onPressed: () => _openGradeEditor(student),
                            ),
                          ],
                        ),
                      ),
                    )),
                if (_students.isEmpty)
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: const Text('No students available for this course yet.', style: TextStyle(color: AppTheme.pureWhite)),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitAllGrades,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureWhite),
                        )
                      : const Text('SAVE ALL GRADES'),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}
