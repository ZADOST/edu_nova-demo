import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

class HRDashboard extends StatelessWidget {
  const HRDashboard({super.key});

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
        title: const Text('Human Resources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.mintGlow),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Stats
            Row(
              children: [
                Expanded(child: _buildStatCard('Active Staff', '124', Icons.people)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('On Leave', '3', Icons.time_to_leave)),
              ],
            ),
            const SizedBox(height: 32),
            
            const Text('Staff Monitoring', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // HR Mock List
            _buildStaffCard('Dr. Alan Turing', 'Computer Science', 'Active'),
            _buildStaffCard('Mr. Akar Shwan', 'IT Support', 'Active'),
            _buildStaffCard('Ms. Tara Ahmed', 'Accounting', 'On Leave', isWarning: true),
            
            const SizedBox(height: 32),
            
            // System Actions
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
          ],
        ),
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
          Text(title, style: TextStyle(color: AppTheme.pureWhite.withOpacity(0.7), fontSize: 14)),
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
                  Text(dept, style: TextStyle(color: AppTheme.pureWhite.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isWarning ? Colors.redAccent.withOpacity(0.2) : AppTheme.mintGlow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isWarning ? Colors.redAccent : AppTheme.mintGlow,
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