import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/models/student_id_card.dart';

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
                            QrImage(
                              data: student.uniqueCode,
                              version: QrVersions.auto,
                              size: 100.0,
                              backgroundColor: Colors.white,
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
