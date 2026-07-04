import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

class PrincipalAssistantDashboard extends StatelessWidget {
  const PrincipalAssistantDashboard({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        title: const Text('Operations Dashboard'),
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
            // Daily Operations Alert
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
                          color: Colors.orangeAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('3 New', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPendingItem('Leave Permission', 'Mr. Akar Shwan', 'IT Support', () => _showMessage(context, 'Reviewing leave permission for Mr. Akar Shwan.')),
                  const Divider(color: Colors.white24),
                  _buildPendingItem('Late Arrival Excuse', 'Shilan Azad', 'Student - 3rd Grade', () => _showMessage(context, 'Reviewing late arrival excuse for Shilan Azad.')),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Daily Attendance Tracking', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildAttendanceCard('Unattended Students', '12', true)),
                const SizedBox(width: 16),
                Expanded(child: _buildAttendanceCard('Absent Teachers', '1', false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItem(String type, String name, String details, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w600)),
              Text('$name • $details', style: TextStyle(color: AppTheme.pureWhite.withOpacity(0.6), fontSize: 12)),
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
          Text(title, style: TextStyle(color: AppTheme.pureWhite.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }
}