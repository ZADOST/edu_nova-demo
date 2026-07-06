import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';
import '../data/alumni_repository.dart';
import 'widgets/event_glass_card.dart';

class AlumniDashboard extends StatefulWidget {
  const AlumniDashboard({super.key});

  @override
  State<AlumniDashboard> createState() => _AlumniDashboardState();
}

class _AlumniDashboardState extends State<AlumniDashboard> {
  final AlumniRepository _repository = AlumniRepository();
  List<AlumniEvent> _events = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _repository.fetchUpcomingEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleRsvp(int index) async {
    final event = _events[index];
    await _repository.toggleRsvp(event.id);
    
    setState(() {
      _events[index].isRsvped = !_events[index].isRsvped;
    });

    _showMessage(
      _events[index].isRsvped 
      ? 'RSVP confirmed for ${event.title}.' 
      : 'RSVP cancelled for ${event.title}.'
    );
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow))
          : _buildCurrentView(),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: AppTheme.darkCharcoal.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
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
                BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'ID Card'),
                BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
                BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0: return _buildIdCardView();
      case 1: return _buildEventsView();
      case 2: return _buildSupportView();
      default: return _buildIdCardView();
    }
  }

  Widget _buildIdCardView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false, pinned: true,
          backgroundColor: AppTheme.darkCharcoal,
          actions: [IconButton(icon: const Icon(Icons.logout, color: AppTheme.mintGlow), onPressed: () => _handleLogout(context))],
          title: const Text('Alumni Network'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(delegate: SliverChildListDelegate([
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppTheme.darkCharcoal, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.mintGlow, width: 2)),
                    child: const Icon(Icons.workspace_premium, color: AppTheme.mintGlow, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class of 2025', style: TextStyle(color: AppTheme.mintGlow, fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Computer Education', style: TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Status: Verified Alumni', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildServiceButton(Icons.description, 'Transcript', () => _showMessage('Transcript request submitted.'))),
                const SizedBox(width: 16),
                Expanded(child: _buildServiceButton(Icons.card_membership, 'Diploma', () => _showMessage('Diploma request submitted.'))),
              ],
            ),
          ])),
        ),
      ],
    );
  }

  Widget _buildEventsView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Upcoming Events', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...List.generate(_events.length, (index) {
            return EventGlassCard(
              event: _events[index],
              onRsvpTap: () => _toggleRsvp(index),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSupportView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Alumni Support', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.volunteer_activism, color: AppTheme.mintGlow, size: 64),
                const SizedBox(height: 16),
                const Text('Mentorship Program', style: TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Give back to the community by mentoring current Computer Education students.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => _showMessage('Joined mentorship program.'), child: const Text('JOIN MENTORS')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.mintGlow, size: 28),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}