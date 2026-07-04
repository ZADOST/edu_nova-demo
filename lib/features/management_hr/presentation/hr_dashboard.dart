import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

class HRDashboard extends StatefulWidget {
  const HRDashboard({super.key});

  @override
  State<HRDashboard> createState() => _HRDashboardState();
}

class _HRDashboardState extends State<HRDashboard> {
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
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Directory'),
                BottomNavigationBarItem(icon: Icon(Icons.event_busy), label: 'Requests'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewView();
      case 1:
        return _buildDirectoryView();
      case 2:
        return _buildRequestsView();
      default:
        return _buildOverviewView();
    }
  }

  // ==========================================
  // TAB 0: OVERVIEW VIEW
  // ==========================================
  Widget _buildOverviewView() {
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
            title: const Text('Human Resources', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
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
              Row(
                children: [
                  Expanded(child: _buildStatCard('Active Staff', '124', Icons.people)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('On Leave', '3', Icons.time_to_leave)),
                ],
              ),
              const SizedBox(height: 32),
              
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HR Operations', style: TextStyle(color: AppTheme.mintGlow, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.person_add, color: AppTheme.pureWhite),
                      title: const Text('Onboard New Teacher', style: TextStyle(color: AppTheme.pureWhite)),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
                      onTap: () {},
                    ),
                    const Divider(color: Colors.white24),
                    ListTile(
                      leading: const Icon(Icons.assessment, color: AppTheme.pureWhite),
                      title: const Text('Performance Reviews', style: TextStyle(color: AppTheme.pureWhite)),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: DIRECTORY VIEW
  // ==========================================
  Widget _buildDirectoryView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Staff Directory', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildStaffCard('Dr. Alan Turing', 'Computer Science', 'Active'),
          _buildStaffCard('Mr. Akar Shwan', 'IT Support', 'Active'),
          _buildStaffCard('Ms. Tara Ahmed', 'Accounting', 'On Leave', isWarning: true),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: REQUESTS VIEW
  // ==========================================
  Widget _buildRequestsView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Leave Requests', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pending Approvals', style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildStaffCard('Prof. Bakhtyar Ali', 'Literature', 'Review Pending', isWarning: true),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.mintGlow),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStaffCard(String name, String dept, String status, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.darkCharcoal,
              child: Text(name[0], style: const TextStyle(color: AppTheme.mintGlow)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(dept, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isWarning ? Colors.orangeAccent.withValues(alpha: 0.2) : AppTheme.mintGlow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isWarning ? Colors.orangeAccent : AppTheme.mintGlow,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}