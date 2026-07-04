import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../data/teacher_repository.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final TeacherRepository _repository = TeacherRepository();
  List<SchoolClass> _todayClasses = [];
  bool _isLoading = true;
  bool _sessionActive = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _repository.fetchTodayClasses();
      setState(() {
        _todayClasses = classes;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
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
        title: const Text('Teacher Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => context.go('/teacher'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.mintGlow),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const Text('Attendance Manager', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Session', style: TextStyle(color: AppTheme.mintGlow, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _sessionActive ? 'Active - students are scanning now.' : 'Session paused. Restart to continue attendance.',
                        style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _sessionActive = !_sessionActive);
                          _showMessage(_sessionActive ? 'Attendance session restarted.' : 'Attendance session paused.');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: _sessionActive ? Colors.redAccent : AppTheme.deepTeal),
                        child: Text(_sessionActive ? 'PAUSE SESSION' : 'RESTART SESSION', style: const TextStyle(color: AppTheme.pureWhite)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Today’s Classes', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._todayClasses.map((schoolClass) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(schoolClass.className, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(schoolClass.time, style: TextStyle(color: AppTheme.mintGlow)),
                            const SizedBox(height: 8),
                            Text('${schoolClass.studentCount} students', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _showMessage('Refreshing attendance for ${schoolClass.className}'),
                              child: const Text('REFRESH ATTENDANCE'),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}
