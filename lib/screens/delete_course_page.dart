import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../database/database_helper.dart';
import '../models/course.dart';

class DeleteCoursePage extends StatefulWidget {
  const DeleteCoursePage({super.key});

  @override
  State<DeleteCoursePage> createState() => _DeleteCoursePageState();
}

class _DeleteCoursePageState extends State<DeleteCoursePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Course> _courses = [];
  Map<int, bool> _selectedCourses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getCourses();
    if (mounted) {
      setState(() {
        _courses = data;
        _selectedCourses = {for (var c in data) c.id!: false};
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSelected() async {
    List<int> toDelete = _selectedCourses.entries.where((e) => e.value).map((e) => e.key).toList();
    if (toDelete.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Delete Subjects?', style: TextStyle(color: Colors.redAccent)),
        content: Text('Are you sure you want to permanently delete ${toDelete.length} subject(s) and unenroll all students assigned to them?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppTheme.mintGlow))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              for (int id in toDelete) {
                await _dbHelper.deleteCourse(id);
              }
              _loadCourses();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${toDelete.length} subjects.')));
            },
            child: const Text('DELETE', style: TextStyle(color: AppTheme.pureWhite)),
          )
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
        title: const Text('Database Admin', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Manage Subjects', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        bool allSelected = _selectedCourses.values.every((v) => v);
                        setState(() => _selectedCourses.updateAll((key, value) => !allSelected));
                      },
                      child: Text(_selectedCourses.values.every((v) => v) ? 'Deselect All' : 'Select All', style: const TextStyle(color: AppTheme.mintGlow)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      child: CheckboxListTile(
                        activeColor: Colors.redAccent,
                        checkColor: AppTheme.pureWhite,
                        side: const BorderSide(color: AppTheme.mintGlow),
                        title: Text(course.courseName, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                        subtitle: Text(course.courseCode, style: const TextStyle(color: Colors.white70)),
                        value: _selectedCourses[course.id],
                        onChanged: (bool? val) => setState(() => _selectedCourses[course.id!] = val ?? false),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedCourses.values.any((v) => v))
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_forever, color: AppTheme.pureWhite),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
                    label: const Text('DELETE SELECTED', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
    );
  }
}