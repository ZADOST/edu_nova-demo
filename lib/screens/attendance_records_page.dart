import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../database/database_helper.dart';
import 'attendance_sheet_page.dart';

class AttendanceRecordsPage extends StatefulWidget {
  const AttendanceRecordsPage({super.key});

  @override
  State<AttendanceRecordsPage> createState() => _AttendanceRecordsPageState();
}

class _AttendanceRecordsPageState extends State<AttendanceRecordsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final db = await _dbHelper.database;
    // Inner join to get subject names
    final data = await db.rawQuery('''
      SELECT s.*, c.course_name 
      FROM attendance_sessions s
      INNER JOIN courses c ON s.course_id = c.id
      ORDER BY s.id DESC
    ''');
    
    if (mounted) {
      setState(() {
        _sessions = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Historical Records', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
        : _sessions.isEmpty
          ? const Center(child: Text('No attendance records found.', style: TextStyle(color: Colors.white70)))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceSheetPage(sessionId: session['id'])));
                  },
                  child: GlassContainer(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session['course_name'], style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Date: ${session['date']}', style: const TextStyle(color: Colors.white70)),
                            Text('${session['total_hours']} Hours', style: const TextStyle(color: AppTheme.mintGlow)),
                          ],
                        ),
                        if (session['topic'] != null && session['topic'].toString().isNotEmpty) ...[
                          const Divider(color: Colors.white24),
                          Text('Topic: ${session['topic']}', style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}