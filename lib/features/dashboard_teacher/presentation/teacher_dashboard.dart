import 'dart:ui';
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
  int _selectedIndex = 0;

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
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        backgroundColor: AppTheme.darkCharcoal,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
            : _buildCurrentView(),
        extendBody: true,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkCharcoal.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BottomNavigationBar(
                backgroundColor: AppTheme.deepTeal.withValues(alpha: 0.8),
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppTheme.mintGlow,
                unselectedItemColor: AppTheme.pureWhite.withValues(alpha: 0.5),
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.qr_code_2), label: 'Attendance'),
                  BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Grades'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeView();
      case 1:
        return _buildAttendanceScannerView();
      case 2:
        return _buildGradingView();
      default:
        return _buildHomeView();
    }
  }

  Future<bool> _handleBackPressed() async {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return false;
    }
    return true;
  }

  void _showPlaceholderMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSectionTopBar(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
            onPressed: () => setState(() => _selectedIndex = 0),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.darkCharcoal,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month, color: AppTheme.mintGlow),
              onPressed: () => context.push('/timetable'),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: AppTheme.mintGlow),
              onPressed: () => context.push('/profile'),
            ),
            IconButton(
              icon: const Icon(Icons.notifications, color: AppTheme.mintGlow),
              onPressed: () => context.push('/notifications'),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: AppTheme.mintGlow),
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.mintGlow),
              onPressed: () => _handleLogout(context),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: const Text('Teacher Portal', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.deepTeal.withValues(alpha: 0.8), AppTheme.darkCharcoal],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.mintGlow.withValues(alpha: 0.2),
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
              const Text('My Classes Today', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
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
                              Text('${c.studentCount} Students', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceScannerView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Attendance'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Session Management', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.qr_code_2, color: AppTheme.darkCharcoal, size: 120),
                      ),
                      const SizedBox(height: 24),
                      const Text('Active Session: Java OOP', style: TextStyle(color: AppTheme.mintGlow, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Display this QR code to the class. Syncs automatically with the Smart Attendance Manager.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _showPlaceholderMessage('Session control will be activated soon.'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('END SESSION', style: TextStyle(color: AppTheme.pureWhite)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Grade Entry'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const SizedBox(height: 8),
                const Text('Grade Entry', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
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
                            value: 'Java OOP',
                            items: [
                              DropdownMenuItem(value: 'Java OOP', child: Text('Advanced Java OOP', style: TextStyle(color: AppTheme.pureWhite))),
                            ],
                            onChanged: (_) => _showPlaceholderMessage('Course selection will be interactive soon.'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildStudentGradeRow('Ahmad Hassan', '92'),
                _buildStudentGradeRow('Shilan Azad', '88'),
                _buildStudentGradeRow('Rebwar Ali', 'Pending...'),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGradeRow(String name, String currentGrade) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600)),
          Row(
            children: [
              Text(currentGrade, style: TextStyle(color: currentGrade.contains('Pending') ? Colors.orangeAccent : AppTheme.mintGlow, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              const Icon(Icons.edit, color: AppTheme.pureWhite, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
