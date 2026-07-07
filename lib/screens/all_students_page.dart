import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../database/database_helper.dart';
import '../models/student.dart';

class AllStudentsPage extends StatefulWidget {
  const AllStudentsPage({super.key});

  @override
  State<AllStudentsPage> createState() => _AllStudentsPageState();
}

class _AllStudentsPageState extends State<AllStudentsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    try {
      final students = await _dbHelper.getAllStudents();
      if (mounted) {
        setState(() {
          _allStudents = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Directory Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents.where((student) {
          final lowerQuery = query.toLowerCase();
          return student.fullName.toLowerCase().contains(lowerQuery) || 
                 student.studentId.toLowerCase().contains(lowerQuery) ||
                 student.grade.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _deleteStudent(Student student) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Confirm Deletion', style: TextStyle(color: AppTheme.pureWhite)),
        content: Text('Are you sure you want to permanently delete ${student.firstName}? This will remove all their grades, attendance records, and financial ledgers.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.mintGlow)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dbHelper.deleteStudent(student.studentId);
              _loadDirectory();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${student.firstName} deleted successfully.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE', style: TextStyle(color: AppTheme.pureWhite)),
          ),
        ],
      ),
    );
  }

  void _showManualAddDialog() {
    final idCtrl = TextEditingController();
    final fNameCtrl = TextEditingController();
    final lNameCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Manual Student Registration', style: TextStyle(color: AppTheme.pureWhite)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                style: const TextStyle(color: AppTheme.pureWhite),
                decoration: const InputDecoration(labelText: 'Student ID (e.g. 1001)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
              ),
              TextField(
                controller: fNameCtrl,
                style: const TextStyle(color: AppTheme.pureWhite),
                decoration: const InputDecoration(labelText: 'First Name', labelStyle: TextStyle(color: AppTheme.mintGlow)),
              ),
              TextField(
                controller: lNameCtrl,
                style: const TextStyle(color: AppTheme.pureWhite),
                decoration: const InputDecoration(labelText: 'Last Name', labelStyle: TextStyle(color: AppTheme.mintGlow)),
              ),
              TextField(
                controller: gradeCtrl,
                style: const TextStyle(color: AppTheme.pureWhite),
                decoration: const InputDecoration(labelText: 'Grade Level (e.g. Grade 10, 11A)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idCtrl.text.isNotEmpty && fNameCtrl.text.isNotEmpty && gradeCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                
                final newStudent = Student(
                  studentId: idCtrl.text.trim(),
                  firstName: fNameCtrl.text.trim(),
                  lastName: lNameCtrl.text.trim(),
                  grade: gradeCtrl.text.trim(),
                  fixedQrData: 'STU-${idCtrl.text.trim()}',
                );

                // This automatically creates their financial ledger too!
                await _dbHelper.addStudent(newStudent);
                _loadDirectory();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fNameCtrl.text} registered successfully.')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            child: const Text('REGISTER STUDENT', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
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
        title: const Text('Master Directory', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.pureWhite),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppTheme.mintGlow),
                    hintText: 'Search by name, ID, or grade...',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  onChanged: _filterSearch,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: ${_filteredStudents.length}', style: const TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
                  const Text('Swipe left to delete', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
                : _filteredStudents.isEmpty
                  ? const Center(child: Text('No students found.', style: TextStyle(color: Colors.white60)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        return Dismissible(
                          key: Key(student.studentId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(Icons.delete_forever, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            _deleteStudent(student);
                            return false; // Let the dialog handle the actual deletion
                          },
                          child: GlassContainer(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
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
                                      Text(student.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('ID: ${student.studentId} | Level: ${student.grade}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code, color: AppTheme.mintGlow),
                                  onPressed: () {
                                    // Optional: Show QR code dialog
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualAddDialog,
        backgroundColor: AppTheme.mintGlow,
        icon: const Icon(Icons.person_add, color: AppTheme.darkCharcoal),
        label: const Text('ADD STUDENT', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
      ),
    );
  }
}