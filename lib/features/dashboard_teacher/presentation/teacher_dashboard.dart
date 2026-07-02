import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';
import '../data/teacher_repository.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final TeacherRepository _repository = TeacherRepository();
  List<SchoolClass> _todayClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final classes = await _repository.fetchTodayClasses();
      setState(() {
        _todayClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final authDb = LocalAuthDb(prefs);
    await authDb.clearSession();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        title: const Text('Teacher Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.mintGlow),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.mintGlow.withOpacity(0.2),
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
                  
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(child: _buildActionCard(Icons.edit_document, 'Enter Grades')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildActionCard(Icons.checklist, 'Attendance')),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text('My Classes Today', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Dynamic List of Classes
                  ..._todayClasses.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.className, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c.time, style: const TextStyle(color: AppTheme.mintGlow)),
                              Text('${c.studentCount} Students', style: TextStyle(color: AppTheme.pureWhite.withOpacity(0.7))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard(IconData icon, String title) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.mintGlow, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}