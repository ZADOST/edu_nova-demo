import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/db/local_auth_db.dart';
import '../../../core/widgets/glass_container.dart';
import '../data/accounting_repository.dart';
import 'widgets/financial_glass_card.dart';

class AccountingDashboard extends StatefulWidget {
  const AccountingDashboard({super.key});

  @override
  State<AccountingDashboard> createState() => _AccountingDashboardState();
}

class _AccountingDashboardState extends State<AccountingDashboard> {
  final AccountingRepository _repository = AccountingRepository();
  List<StudentFinance> _finances = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _repository.fetchStudentFinances();
      setState(() {
        _finances = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlockStatus(int index) async {
    final student = _finances[index];
    final newStatus = await _repository.toggleStudentBlockStatus(student.studentId, student.isBlocked);
    
    setState(() {
      _finances[index].isBlocked = newStatus;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? '${student.name} has been BLOCKED' : '${student.name} is now ACTIVE'),
          backgroundColor: newStatus ? Colors.redAccent : AppTheme.deepTeal,
        ),
      );
    }
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
                BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Revenue'),
                BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Installments'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
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
        return _buildRevenueView();
      case 1:
        return _buildInstallmentsView();
      case 2:
        return _buildInvoicesView();
      default:
        return _buildRevenueView();
    }
  }

  // ==========================================
  // TAB 0: REVENUE OVERVIEW
  // ==========================================
  Widget _buildRevenueView() {
    double totalCollected = _finances.fold(0, (sum, item) => sum + item.paidAmount);
    double totalExpected = _finances.fold(0, (sum, item) => sum + item.totalFees);

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
            title: const Text('Financial Overview', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Semester Revenue (IQD)', style: TextStyle(color: AppTheme.mintGlow, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(totalCollected.toStringAsFixed(0), style: const TextStyle(color: AppTheme.pureWhite, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalExpected > 0 ? totalCollected / totalExpected : 0,
                      backgroundColor: AppTheme.darkCharcoal,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mintGlow),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text('Target: ${totalExpected.toStringAsFixed(0)}', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Total Students', '${_finances.length}', Icons.school)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard('Blocked Accounts', '${_finances.where((f) => f.isBlocked).length}', Icons.block)),
                ],
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 1: INSTALLMENTS MANAGER
  // ==========================================
  Widget _buildInstallmentsView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Student Installments', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Manage 5-installment plans and block/unblock system access.', style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          ...List.generate(_finances.length, (index) {
            return FinancialGlassCard(
              financeRecord: _finances[index],
              onToggleBlock: () => _toggleBlockStatus(index),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: INVOICES VIEW
  // ==========================================
  Widget _buildInvoicesView() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Generate Invoices', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.receipt_long, color: AppTheme.mintGlow, size: 64),
                const SizedBox(height: 16),
                const Text('Automated Billing', style: TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Generate and distribute upcoming installment invoices to all active students.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {}, 
                  child: const Text('DISPATCH INVOICES'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.mintGlow),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }
}