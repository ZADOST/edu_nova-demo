import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';

class AlumniDashboard extends StatefulWidget {
  const AlumniDashboard({super.key});

  @override
  State<AlumniDashboard> createState() => _AlumniDashboardState();
}

class _AlumniDashboardState extends State<AlumniDashboard> {
  int _selectedIndex = 0;
  final bool _isLoading = false;

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
      onWillPop: () async {
        if (_selectedIndex != 0) { setState(() => _selectedIndex = 0); return false; }
        return true;
      },
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
                onTap: (index) => setState(() => _selectedIndex = index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Network'),
                  BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
                  BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Careers'),
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
      case 0: return _buildNetworkView();
      case 1: return _buildEventsView();
      case 2: return _buildCareersView();
      default: return _buildNetworkView();
    }
  }

  Widget _buildSectionTopBar(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_selectedIndex != 0)
                IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow), onPressed: () => setState(() => _selectedIndex = 0)),
              Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.mintGlow),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Alumni Portal'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 35, backgroundColor: AppTheme.mintGlow.withValues(alpha: 0.2), child: const Icon(Icons.school, size: 35, color: AppTheme.mintGlow)),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome Back!', style: TextStyle(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Class of 2025 | Engineering', style: TextStyle(color: AppTheme.mintGlow, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Alumni Directory', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildDirectoryCard('Alex Johnson', 'Senior Application Developer', 'City Center'),
                _buildDirectoryCard('Sarah Chen', 'Data Analyst', 'North Campus District'),
                _buildDirectoryCard('Michael Davis', 'Network Engineer', 'Metropolis Tech Park'),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryCard(String name, String role, String location) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppTheme.deepTeal, child: Text(name[0], style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(role, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(location, style: const TextStyle(color: AppTheme.mintGlow, fontSize: 11)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.message, color: AppTheme.mintGlow), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildEventsView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Campus Events'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const Text('Stay Connected to the University', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 24),
                _buildEventCard(
                  title: 'Annual Tech & Innovation Summit',
                  date: 'October 15, 2026',
                  time: '10:00 AM - 02:00 PM',
                  location: 'University Main Campus',
                  description: 'Join the annual technology summit. Alumni are invited to network and mentor current students in the engineering and business faculties.',
                  isFeatured: true,
                ),
                _buildEventCard(
                  title: 'Annual Engineering Alumni Dinner',
                  date: 'November 05, 2026',
                  time: '07:00 PM',
                  location: 'Grand City Hotel',
                  description: 'A networking dinner for all engineering and IT faculty graduates.',
                  isFeatured: false,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({required String title, required String date, required String time, required String location, required String description, required bool isFeatured}) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFeatured)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.mintGlow.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: const Text('FEATURED EVENT', style: TextStyle(color: AppTheme.mintGlow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [const Icon(Icons.calendar_today, color: Colors.white54, size: 14), const SizedBox(width: 8), Text(date, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.access_time, color: Colors.white54, size: 14), const SizedBox(width: 8), Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on, color: Colors.white54, size: 14), const SizedBox(width: 8), Text(location, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
          const Divider(color: Colors.white24, height: 24),
          Text(description, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8), fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RSVP Confirmed for $title')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepTeal, minimumSize: const Size(double.infinity, 45)),
            child: const Text('RSVP NOW', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildCareersView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Job Board'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const Text('Exclusive opportunities from our corporate partners.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                const SizedBox(height: 24),
                _buildJobCard(
                  title: 'Full-Stack Developer',
                  company: 'Global Tech Solutions',
                  location: 'On-site',
                  type: 'Full-time',
                  salary: '\$80,000 - \$100,000',
                ),
                _buildJobCard(
                  title: 'Database Administrator (MySQL)',
                  company: 'Acme Corp',
                  location: 'Hybrid',
                  type: 'Full-time',
                  salary: 'Competitive',
                ),
                _buildJobCard(
                  title: 'Junior Mobile Engineer',
                  company: 'Innovation Labs',
                  location: 'Remote',
                  type: 'Contract',
                  salary: '\$65,000',
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard({required String title, required String company, required String location, required String type, required String salary}) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(company, style: const TextStyle(color: AppTheme.mintGlow, fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.deepTeal, borderRadius: BorderRadius.circular(8)),
                child: Text(type, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [const Icon(Icons.location_city, color: Colors.white54, size: 14), const SizedBox(width: 8), Text(location, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.payments, color: Colors.white54, size: 14), const SizedBox(width: 8), Text(salary, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application sent to $company')));
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.mintGlow),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('APPLY NOW', style: TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}