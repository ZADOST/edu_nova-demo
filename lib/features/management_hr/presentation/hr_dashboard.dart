import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../database/database_helper.dart';

class HRDashboard extends StatefulWidget {
  const HRDashboard({super.key});

  @override
  State<HRDashboard> createState() => _HRDashboardState();
}

class _HRDashboardState extends State<HRDashboard> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Map<String, dynamic>> _staffDirectory = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _payrollHistory = [];
  
  bool _isLoading = true;
  int _selectedIndex = 0;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'ar_IQ', symbol: 'IQD ');

  @override
  void initState() {
    super.initState();
    _seedHRData();
    _loadHRData();
  }

  // Ensures we have data to demo
  Future<void> _seedHRData() async {
    final teachers = await _dbHelper.getTeachers();
    if (teachers.isEmpty) {
      await _dbHelper.addTeacher('T-001', 'Mr. Abdulrahman Jakhsi', 'Computer Education', salary: 1800000.0);
      await _dbHelper.addTeacher('T-002', 'Mr. Akar Shwan', 'Mobile Development', salary: 1500000.0);
      await _dbHelper.addTeacher('T-003', 'Ms. Tara Ahmed', 'Accounting', salary: 1200000.0);
      
      // Seed a pending leave request
      await _dbHelper.submitLeaveRequest('T-003', '2026-08-01', '2026-08-14', 'Annual Medical Leave');
    }
  }

  Future<void> _loadHRData() async {
    setState(() => _isLoading = true);
    try {
      final staff = await _dbHelper.getTeachers();
      final leaves = await _dbHelper.getAllLeaveRequests();
      final payroll = await _dbHelper.getPayrollHistory();
      
      if (mounted) {
        setState(() {
          _staffDirectory = staff;
          _leaveRequests = leaves;
          _payrollHistory = payroll;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("HR Stats Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final authDb = LocalAuthDb(prefs);
    await authDb.clearSession();
    if (context.mounted) context.go('/login');
  }

  void _openOnboardingDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Onboard New Staff', style: TextStyle(color: AppTheme.pureWhite)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: idCtrl, style: const TextStyle(color: AppTheme.pureWhite), decoration: const InputDecoration(labelText: 'Staff ID (e.g. T-004)', labelStyle: TextStyle(color: AppTheme.mintGlow))),
              TextField(controller: nameCtrl, style: const TextStyle(color: AppTheme.pureWhite), decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: AppTheme.mintGlow))),
              TextField(controller: deptCtrl, style: const TextStyle(color: AppTheme.pureWhite), decoration: const InputDecoration(labelText: 'Department', labelStyle: TextStyle(color: AppTheme.mintGlow))),
              TextField(controller: salaryCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.pureWhite), decoration: const InputDecoration(labelText: 'Base Salary (IQD)', labelStyle: TextStyle(color: AppTheme.mintGlow))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              if (idCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty && salaryCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _dbHelper.addTeacher(
                  idCtrl.text, 
                  nameCtrl.text, 
                  deptCtrl.text.isEmpty ? 'General' : deptCtrl.text,
                  salary: double.parse(salaryCtrl.text),
                );
                _loadHRData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameCtrl.text} onboarded successfully.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            child: const Text('ONBOARD', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.mintGlow)) : _buildCurrentView(),
        extendBody: true,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: AppTheme.darkCharcoal.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))],
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
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
                  BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Directory'),
                  BottomNavigationBarItem(icon: Icon(Icons.event_busy), label: 'Leaves'),
                  BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Payroll'),
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
      case 0: return _buildOverviewView();
      case 1: return _buildDirectoryView();
      case 2: return _buildLeaveView();
      case 3: return _buildPayrollView();
      default: return _buildOverviewView();
    }
  }

  Widget _buildOverviewView() {
    final activeCount = _staffDirectory.where((s) => s['status'] == 'Active').length;
    final leaveCount = _staffDirectory.where((s) => s['status'] == 'On Leave').length;
    final pendingLeaves = _leaveRequests.where((l) => l['status'] == 'Pending').length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false, pinned: true, backgroundColor: AppTheme.darkCharcoal, elevation: 0,
          actions: [IconButton(icon: const Icon(Icons.logout, color: AppTheme.mintGlow), onPressed: () => _handleLogout(context))],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: const Text('Human Resources', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
            background: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.deepTeal.withValues(alpha: 0.8), AppTheme.darkCharcoal]))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(child: _buildStatCard('Active Staff', '$activeCount', Icons.check_circle_outline, Colors.greenAccent)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('On Leave', '$leaveCount', Icons.time_to_leave, Colors.orangeAccent)),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatCard('Pending Leaves', '$pendingLeaves', Icons.pending_actions, AppTheme.mintGlow),
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
                      title: const Text('Onboard New Staff', style: TextStyle(color: AppTheme.pureWhite)),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
                      onTap: _openOnboardingDialog,
                    ),
                    const Divider(color: Colors.white24),
                    ListTile(
                      leading: const Icon(Icons.payments, color: AppTheme.pureWhite),
                      title: const Text('Process Monthly Payroll', style: TextStyle(color: AppTheme.pureWhite)),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
                      onTap: () => setState(() => _selectedIndex = 3),
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

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTopBar(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow), onPressed: () => setState(() => _selectedIndex = 0)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDirectoryView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Staff Directory'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                ElevatedButton.icon(
                  onPressed: _openOnboardingDialog,
                  icon: const Icon(Icons.person_add, color: AppTheme.darkCharcoal),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow, padding: const EdgeInsets.symmetric(vertical: 16)),
                  label: const Text('ONBOARD NEW STAFF', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                ..._staffDirectory.map((staff) {
                  bool isActive = staff['status'] == 'Active';
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.deepTeal,
                          child: Text(staff['full_name'][0], style: const TextStyle(color: AppTheme.pureWhite)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(staff['full_name'], style: const TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${staff['department']} | ID: ${staff['teacher_id']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: Text(staff['status'], style: TextStyle(color: isActive ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveView() {
    final pending = _leaveRequests.where((l) => l['status'] == 'Pending').toList();
    final processed = _leaveRequests.where((l) => l['status'] != 'Pending').toList();

    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Leave Management'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const Text('Pending Approvals', style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (pending.isEmpty) const Text('No pending requests.', style: TextStyle(color: Colors.white60)),
                ...pending.map((req) => _buildLeaveCard(req, isPending: true)),
                
                const SizedBox(height: 24),
                const Text('Processed Requests', style: TextStyle(color: AppTheme.mintGlow, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (processed.isEmpty) const Text('No history found.', style: TextStyle(color: Colors.white60)),
                ...processed.map((req) => _buildLeaveCard(req, isPending: false)),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> req, {required bool isPending}) {
    Color statusColor = req['status'] == 'Approved' ? Colors.green : (isPending ? Colors.orangeAccent : Colors.redAccent);
    
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(req['full_name'], style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(req['status'], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${req['start_date']} to ${req['end_date']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text('Reason: ${req['reason']}', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8), fontSize: 12, fontStyle: FontStyle.italic)),
          if (isPending) ...[
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await _dbHelper.updateLeaveStatus(req['id'], 'Rejected', req['teacher_id']);
                    _loadHRData();
                  },
                  child: const Text('REJECT', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _dbHelper.updateLeaveStatus(req['id'], 'Approved', req['teacher_id']);
                    _loadHRData();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('APPROVE', style: TextStyle(color: AppTheme.pureWhite)),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildPayrollView() {
    String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Payroll Processing'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance, color: AppTheme.mintGlow, size: 48),
                      const SizedBox(height: 16),
                      Text('Payroll Cycle: $currentMonth', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _dbHelper.processMonthlyPayroll(currentMonth);
                          _loadHRData();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payroll processed successfully!')));
                        },
                        icon: const Icon(Icons.check_circle, color: AppTheme.darkCharcoal),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow, minimumSize: const Size(double.infinity, 50)),
                        label: const Text('DISBURSE FUNDS', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Disbursement History', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                if (_payrollHistory.isEmpty)
                  const Text('No payroll records found.', style: TextStyle(color: Colors.white60))
                else
                  ..._payrollHistory.map((p) => GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['full_name'], style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                              Text(p['month'], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_currencyFormat.format(p['net_paid']), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(p['status'], style: const TextStyle(color: Colors.white60, fontSize: 10)),
                          ],
                        )
                      ],
                    ),
                  )),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}