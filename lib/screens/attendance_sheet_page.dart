import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/theme/app_theme.dart';
import '../database/database_helper.dart';

class AttendanceSheetPage extends StatefulWidget {
  final int sessionId;
  const AttendanceSheetPage({super.key, required this.sessionId});

  @override
  State<AttendanceSheetPage> createState() => _AttendanceSheetPageState();
}

class _AttendanceSheetPageState extends State<AttendanceSheetPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isGenerating = true;

  @override
  void initState() {
    super.initState();
    _generateAndPrintPdf();
  }

  Future<void> _generateAndPrintPdf() async {
    final pdf = pw.Document();
    final db = await _dbHelper.database;
    
    // Fetch Data
    var sessionData = await db.rawQuery('''
      SELECT s.*, c.course_name, c.course_code 
      FROM attendance_sessions s
      INNER JOIN courses c ON s.course_id = c.id
      WHERE s.id = ?
    ''', [widget.sessionId]);
    
    if (sessionData.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    
    var session = sessionData.first;
    var records = await db.query('attendance_records', where: 'session_id = ?', whereArgs: [widget.sessionId]);
    var students = await db.rawQuery('''
      SELECT s.student_id, s.first_name, s.last_name 
      FROM students s
      INNER JOIN enrollments e ON s.student_id = e.student_id
      WHERE e.course_id = ?
    ''', [session['course_id']]);

    // Build PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Edu Nova Attendance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Subject: ${session['course_name']} (${session['course_code']})'),
              pw.Text('Date: ${session['date']} | Total Hours: ${session['total_hours']}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                data: <List<String>>[
                  ['Student ID', 'Name', 'Status Overview'],
                  ...students.map((stu) {
                    // Quick status summary logic
                    int present = records.where((r) => r['student_id'] == stu['student_id'] && r['status'] == 'present').length;
                    return [
                      stu['student_id'].toString(),
                      '${stu['first_name']} ${stu['last_name']}',
                      '$present / ${session['total_hours']} Hours Present'
                    ];
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    setState(() => _isGenerating = false);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    
    if (mounted) Navigator.pop(context); // Return to previous screen after print dialog closes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.mintGlow),
            const SizedBox(height: 24),
            Text(_isGenerating ? 'Compiling PDF Report...' : 'Opening Print Dialog...', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}