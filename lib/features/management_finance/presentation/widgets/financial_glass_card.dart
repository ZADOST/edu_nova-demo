import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../data/accounting_repository.dart';

class FinancialGlassCard extends StatelessWidget {
  final StudentFinance financeRecord;
  final VoidCallback onToggleBlock;

  const FinancialGlassCard({
    super.key,
    required this.financeRecord,
    required this.onToggleBlock,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWarning = financeRecord.installmentsPaid < 2 && financeRecord.remainingBalance > 0;
    final Color progressColor = isWarning ? Colors.redAccent : AppTheme.mintGlow;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Circular Installment Progress
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: financeRecord.progressPercentage,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.darkCharcoal,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                Center(
                  child: Text(
                    '${financeRecord.installmentsPaid}/5',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  financeRecord.name,
                  style: const TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining: \$${financeRecord.remainingBalance.toStringAsFixed(0)}',
                  style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.7), fontSize: 14),
                ),
              ],
            ),
          ),

          // Block/Unblock Action
          Column(
            children: [
              Switch(
                value: !financeRecord.isBlocked, // True means active, False means blocked
                activeThumbColor: AppTheme.mintGlow,
                inactiveThumbColor: Colors.redAccent,
                inactiveTrackColor: Colors.redAccent.withValues(alpha: 0.3),
                onChanged: (val) => onToggleBlock(),
              ),
              Text(
                financeRecord.isBlocked ? 'BLOCKED' : 'ACTIVE',
                style: TextStyle(
                  color: financeRecord.isBlocked ? Colors.redAccent : AppTheme.mintGlow,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}