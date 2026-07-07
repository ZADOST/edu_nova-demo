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
  double _totalExpected = 0.0;
  double _totalCollected = 0.0;
  
  bool _isLoading = true;
  int _selectedIndex = 0;
  
  final NumberFormat _usdFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    try {
      final records = await _dbHelper.getFinancialRecords();
      
      double expected = 0.0;
      double collected = 0.0;
      
      for (var r in records) {
        expected += r['total_tuition'] as double;
        collected += r['amount_paid'] as double;
      }
      
      if (mounted) {
        setState(() {
          _financeRecords = records;
          _totalExpected = expected;
          _totalCollected = collected;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Finance Load Error: $e");
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: Text('Record Payment: ${record['first_name']}', style: const TextStyle(color: AppTheme.pureWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance Due: ${_usdFormat.format(record['total_tuition'] - record['amount_paid'])}', style: const TextStyle(color: Colors.orangeAccent)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.pureWhite),
              decoration: const InputDecoration(labelText: 'Payment Amount (USD)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment recorded for ${record['first_name']}.')));
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
                  BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Tuition'),
                  BottomNavigationBarItem(icon: Icon(Icons.block), label: 'Clearance'),
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
      case 2: return _buildClearanceView();
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
    double progress = _totalExpected == 0 ? 0 : (_totalCollected / _totalExpected);
    
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
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Tuition Collected', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_usdFormat.format(_totalCollected), style: const TextStyle(color: AppTheme.mintGlow, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress, backgroundColor: AppTheme.darkCharcoal, color: AppTheme.mintGlow, minHeight: 8),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).toStringAsFixed(1)}% of Expected ${_usdFormat.format(_totalExpected)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Department Access', style: TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppTheme.mintGlow),
                title: const Text('Log Student Payments', style: TextStyle(color: AppTheme.pureWhite)),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.mintGlow),
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.orangeAccent),
                title: const Text('Financial Clearance & Holds', style: TextStyle(color: AppTheme.pureWhite)),
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
          _buildSectionTopBar('Student Tuition'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                if (_financeRecords.isEmpty)
                  const Text('No students registered in the system yet.', style: TextStyle(color: Colors.white60))
                else
                  ..._financeRecords.map((record) {
                    double balance = record['total_tuition'] - record['amount_paid'];
                    bool isPaid = balance <= 0;
                    
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${record['first_name']} ${record['last_name']}', style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                              if (isPaid)
                                const Icon(Icons.verified, color: Colors.greenAccent)
                              else
                                Text('Due: ${_usdFormat.format(balance)}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('ID: ${record['student_id']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Paid: ${_usdFormat.format(record['amount_paid'])}', style: const TextStyle(color: AppTheme.mintGlow, fontSize: 14)),
                              if (!isPaid)
                                ElevatedButton(
                                  onPressed: () => _showPaymentDialog(record),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepTeal, visualDensity: VisualDensity.compact),
                                  child: const Text('+ PAYMENT', style: TextStyle(color: AppTheme.pureWhite, fontSize: 12)),
                                ),
                            ],
                          )
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

  Widget _buildClearanceView() {
    return SafeArea(
      child: Column(
        children: [
          _buildSectionTopBar('Financial Clearance'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              children: [
                const Text('Place a financial hold to block a student from accessing midterms or final exams due to unpaid installments.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                const SizedBox(height: 24),
                
                if (_financeRecords.isEmpty)
                  const Text('No students registered in the system yet.', style: TextStyle(color: Colors.white60))
                else
                  ..._financeRecords.map((record) {
                    bool isBlocked = record['is_blocked'] == 1;
                    double balance = record['total_tuition'] - record['amount_paid'];
                    
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
                                Text('${record['first_name']} ${record['last_name']}', style: TextStyle(color: isBlocked ? Colors.redAccent : AppTheme.pureWhite, fontWeight: FontWeight.bold, decoration: isBlocked ? TextDecoration.lineThrough : null)),
                                const SizedBox(height: 4),
                                Text('Balance: ${_usdFormat.format(balance)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: isBlocked,
                            activeColor: Colors.redAccent,
                            inactiveThumbColor: AppTheme.mintGlow,
                            inactiveTrackColor: AppTheme.deepTeal,
                            onChanged: (bool value) async {
                              await _dbHelper.toggleFinancialBlock(record['student_id'], value);
                              _loadFinancialData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? '${record['first_name']} has been blocked.' : '${record['first_name']} clearance granted.')));
                              }
                            },
                          )
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
}