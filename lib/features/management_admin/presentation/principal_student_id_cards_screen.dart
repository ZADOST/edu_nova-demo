import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/models/student_id_card.dart';
import '../../../core/data/student_id_card_repository.dart';

class PrincipalStudentIdCardsScreen extends StatefulWidget {
  const PrincipalStudentIdCardsScreen({super.key});

  @override
  State<PrincipalStudentIdCardsScreen> createState() => _PrincipalStudentIdCardsScreenState();
}

class _PrincipalStudentIdCardsScreenState extends State<PrincipalStudentIdCardsScreen> {
  final List<StudentIdCard> _students = [
    StudentIdCard(id: '1001', name: 'Ahmad Hassan', department: 'Computer Education', course: 'Advanced Java OOP', batch: '2026'),
    StudentIdCard(id: '1002', name: 'Shilan Azad', department: 'Kurdish Literature', course: 'Kurdish Literature & Poetry', batch: '2026'),
    StudentIdCard(id: '1003', name: 'Rebwar Ali', department: 'Software Engineering', course: 'Mobile App Dev (Flutter)', batch: '2026'),
  ];
  
  void _openAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    final batchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Register New Student', style: TextStyle(color: AppTheme.pureWhite)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, style: const TextStyle(color: AppTheme.pureWhite), decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: AppTheme.mintGlow))),
              const SizedBox(height: 8),
              TextField(controller: deptCtrl, style: const TextStyle(color: AppTheme.pureWhite), decoration: const InputDecoration(labelText: 'Department', labelStyle: TextStyle(color: AppTheme.mintGlow))),
              const SizedBox(height: 8),
              TextField(controller: courseCtrl, style: const TextStyle(color: AppTheme.pureWhite), decoration: const InputDecoration(labelText: 'Course', labelStyle: TextStyle(color: AppTheme.mintGlow))),
              const SizedBox(height: 8),
              TextField(controller: batchCtrl, style: const TextStyle(color: AppTheme.pureWhite), decoration: const InputDecoration(labelText: 'Batch', labelStyle: TextStyle(color: AppTheme.mintGlow))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL', style: TextStyle(color: AppTheme.mintGlow))),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final dept = deptCtrl.text.trim();
              final course = courseCtrl.text.trim();
              final batch = batchCtrl.text.trim().isEmpty ? '2026' : batchCtrl.text.trim();
              if (name.isEmpty || dept.isEmpty || course.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                return;
              }
              final student = StudentIdCardRepository.addStudent(name: name, department: dept, course: course, batch: batch);
              setState(() => _students.add(student));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Student ${student.name} added with ID ${student.uniqueCode}')));
            },
            child: const Text('REGISTER', style: TextStyle(color: AppTheme.mintGlow)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Generate Student ID Cards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => context.go('/principal'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: AppTheme.mintGlow),
            onPressed: _openAddStudentDialog,
            tooltip: 'Register New Student',
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text('Student ID Cards', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ..._students.map((student) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student.name, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('ID: ${student.uniqueCode}', style: TextStyle(color: AppTheme.mintGlow)),
                                  const SizedBox(height: 4),
                                  Text(student.department, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                                  const SizedBox(height: 4),
                                  Text('${student.course} • Batch ${student.batch}', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: QrImageView(
                                data: student.uniqueCode,
                                size: 100,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _showMessage('Copied ${student.uniqueCode} QR code details.'),
                          child: const Text('PRINT/SHARE ID CARD'),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
