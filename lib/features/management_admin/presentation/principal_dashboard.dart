import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  int _selectedIndex = 0;

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
      body: _buildCurrentView(),
      
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
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Alerts'),
                BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'Attendance'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity Logs'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0: return _buildAlertsView();
      case 1: return _buildAttendanceView();
      case 2: return _buildLogsView();
      default: return _buildAlertsView();
    }
  }

  // ==========================================
  // TAB 0: OPERATIONAL ALERTS
  // ==========================================
  Widget _buildAlertsView() {
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
              icon: const Icon(Icons.logout, color: AppTheme.mintGlow),
              onPressed: () => _handleLogout(context),
            )
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: const Text('Operations Dashboard', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        const Text('Pending Approvals', style: TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('3 New', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPendingItem('Leave Permission', 'Mr. Akar Shwan', 'IT Support'),
                    const Divider(color: Colors.white24),
                    _buildPendingItem('Late Arrival Excuse', 'Shilan Azad', 'Student - 3rd Grade'),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: DAILY ATTENDANCE
  // ==========================================
  Widget _buildAttendanceView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Attendance Tracking', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildAttendanceCard('Unattended Students', '12', true)),
              const SizedBox(width: 16),
              Expanded(child: _buildAttendanceCard('Absent Teachers', '1', false)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ACTIVITY LOGS
  // ==========================================
  Widget _buildLogsView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Campus Activity Log', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...List.generate(5, (index) => _buildLogItem('2026-07-04 10:45 AM', 'System Access Granted - Principal')),
        ],
      ),
    );
  }

  Widget _buildPendingItem(String type, String name, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600)),
              Text('$name   $details', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 12)),
            ],
          ),
          const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(String title, String count, bool isCritical) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count, style: TextStyle(color: isCritical ? Colors.redAccent : AppTheme.mintGlow, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLogItem(String timestamp, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timestamp, style: TextStyle(color: AppTheme.mintGlow, fontSize: 10)),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}