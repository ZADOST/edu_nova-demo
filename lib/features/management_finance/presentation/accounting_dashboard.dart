import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../database/database_helper.dart';

class AccountingDashboard extends StatefulWidget {
  const AccountingDashboard({super.key});

  @override
  State<AccountingDashboard> createState() => _AccountingDashboardState();
}

class _AccountingDashboardState extends State<AccountingDashboard> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Map<String, dynamic>> _financeRecords = [];
  List<Map<String, dynamic>> _payrollHistory = [];
  
  double _totalExpectedTuition = 0.0;
  double _totalCollectedTuition = 0.0;
  
  double _projectedPayrollLiability = 0.0;
  int _activeStaffCount = 0;
  double _totalStaffDisbursed = 0.0;
  
  bool _isLoading = true;
  int _selectedIndex = 0;

  final NumberFormat _iqdFormat = NumberFormat.currency(locale: 'ar_IQ', symbol: 'IQD ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load Student Financial Ledger Data
      final studentRecords = await _dbHelper.getFinancialRecords();
      double expectedTuition = 0.0;
      double collectedTuition = 0.0;
      for (var r in studentRecords) {
        expectedTuition += r['total_tuition'] as double;
        collectedTuition += r['amount_paid'] as double;
      }

      // 2. Load HR's Active Teacher Salary Liability
      final teachers = await _dbHelper.getTeachers();
      double projectedLiability = 0.0;
      int activeStaff = 0;
      for (var t in teachers) {
        if (t['status'] == 'Active') {
          projectedLiability += (t['salary'] as double);
          activeStaff++;
        }
      }

      // 3. Load Actually Disbursed Payroll
      final payrollRecords = await _dbHelper.getPayrollHistory();
      double totalDisbursed = 0.0;
      for (var p in payrollRecords) {
        totalDisbursed += p['net_paid'] as double;
      }

      if (mounted) {
        setState(() {
          _financeRecords = studentRecords;
          _totalExpectedTuition = expectedTuition;
          _totalCollectedTuition = collectedTuition;
          
          _projectedPayrollLiability = projectedLiability;
          _activeStaffCount = activeStaff;
          
          _payrollHistory = payrollRecords;
          _totalStaffDisbursed = totalDisbursed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Finance Dashboard Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final authDb = LocalAuthDb(prefs);
    await authDb.clearSession();
    if (context.mounted) context.go('/login');
  }

  void _showPaymentDialog(Map<String, dynamic> record) {
    final amountCtrl = TextEditingController();
    
    // Calculate how much 1 installment should cost based on their total tuition
    double installmentSize = (record['total_tuition'] as double) / 5;
    
    // Automatically suggest the exact amount of 1 installment for the accountant
    amountCtrl.text = installmentSize.toInt().toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: Text('Collect Installment: ${record['first_name']}', style: const TextStyle(color: AppTheme.pureWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance Due: ${_iqdFormat.format(record['total_tuition'] - record['amount_paid'])}', style: const TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.pureWhite),
              decoration: const InputDecoration(labelText: 'Payment Amount (IQD)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            onPressed: () async {
              if (amountCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _dbHelper.recordTuitionPayment(record['student_id'], double.parse(amountCtrl.text));
                _loadFinancialData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            child: const Text('RECORD PAYMENT', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
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
                  BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Overview'),
                  BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Tuition (In)'),
                  BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), label: 'Payroll (Out)'),
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
      case 1: return _buildTuitionView();
      case 2: return _buildStaffPayrollView();
      default: return _buildOverviewView();
    }
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

  Widget _buildOverviewView() {
    double tuitionProgress = _totalExpectedTuition == 0 ? 0 : (_totalCollectedTuition / _totalExpectedTuition);
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false, pinned: true, backgroundColor: AppTheme.darkCharcoal, elevation: 0,
          actions: [IconButton(icon: const Icon(Icons.logout, color: AppTheme.mintGlow), onPressed: () => _handleLogout(context))],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: const Text('Finance & Accounting', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
            background: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.deepTeal.withValues(alpha: 0.8), AppTheme.darkCharcoal]))),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Student Inflow Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Tuition Collected (Revenue)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_iqdFormat.format(_totalCollectedTuition), style: const TextStyle(color: AppTheme.mintGlow, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: tuitionProgress, backgroundColor: AppTheme.darkCharcoal, color: AppTheme.mintGlow, minHeight: 6),
                    const SizedBox(height: 8),
                    Text('${(tuitionProgress * 100).toStringAsFixed(1)}% of Expected ${_iqdFormat.format(_totalExpectedTuition)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Staff Liability Card - DIRECTLY READS HR'S LIVE TEACHER DATA
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Projected Payroll Liability (Monthly)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_iqdFormat.format(_projectedPayrollLiability), style: const TextStyle(color: Colors.orangeAccent, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Pending HR Disbursement for $_activeStaffCount active staff members', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Quick Access Ledgers', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppTheme.mintGlow),
                title: const Text('Student Payments Ledger'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.badge_outlined, color: Colors.blueAccent),
                title: const Text('Staff Salary Disbursements'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTuitionView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Student Tuition Inflow'),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: _financeRecords.length,
              itemBuilder: (context, index) {
                final record = _financeRecords[index];
                
                // Installment Calculation Logic
                double totalTuition = record['total_tuition'] as double;
                double amountPaid = record['amount_paid'] as double;
                double balance = totalTuition - amountPaid;
                
                double installmentSize = totalTuition / 5;
                int installmentsPaid = (amountPaid / installmentSize).floor();
                if (installmentsPaid > 5) installmentsPaid = 5;
                
                bool isPaid = balance <= 0;
                
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${record['first_name']} ${record['last_name']}', style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('ID: ${record['student_id']} | Grade: ${record['grade']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Paid: ${_iqdFormat.format(amountPaid)} ', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 12)),
                              Text('($installmentsPaid/5 Installments)', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7), fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          )
                        ],
                      ),
                      isPaid 
                        ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                        : ElevatedButton(
                            onPressed: () => _showPaymentDialog(record),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepTeal, visualDensity: VisualDensity.compact),
                            child: const Text('Collect', style: TextStyle(color: AppTheme.pureWhite, fontSize: 12)),
                          )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPayrollView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Staff Salary Ledger'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Disbursement Breakdown', style: TextStyle(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.refresh, color: AppTheme.mintGlow), onPressed: _loadFinancialData),
              ],
            ),
          ),
          Expanded(
            child: _payrollHistory.isEmpty
              ? const Center(child: Text('No payroll disbursed yet. Go to HR and click "Disburse Funds" first.', style: TextStyle(color: Colors.white54), textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: _payrollHistory.length,
                  itemBuilder: (context, index) {
                    final payroll = _payrollHistory[index];
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(payroll['full_name'], style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Staff ID: ${payroll['teacher_id']} | Dept: ${payroll['department']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('Cycle: ${payroll['month']}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_iqdFormat.format(payroll['net_paid']), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Text('Deposited', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}