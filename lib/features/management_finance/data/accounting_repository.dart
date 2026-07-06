import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentFinance {
  final String studentId;
  final String name;
  final double totalFees;
  final double paidAmount;
  final int installmentsPaid; // Out of 5
  bool isBlocked;

  StudentFinance({
    required this.studentId,
    required this.name,
    required this.totalFees,
    required this.paidAmount,
    required this.installmentsPaid,
    this.isBlocked = false,
  });

  double get remainingBalance => totalFees - paidAmount;
  double get progressPercentage => installmentsPaid / 5;

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'name': name,
    'totalFees': totalFees,
    'paidAmount': paidAmount,
    'installmentsPaid': installmentsPaid,
    'isBlocked': isBlocked,
  };

  factory StudentFinance.fromJson(Map<String, dynamic> json) => StudentFinance(
    studentId: json['studentId'],
    name: json['name'],
    totalFees: (json['totalFees'] as num).toDouble(),
    paidAmount: (json['paidAmount'] as num).toDouble(),
    installmentsPaid: json['installmentsPaid'],
    isBlocked: json['isBlocked'],
  );
}

class AccountingRepository {
  static const String _financeKey = 'local_finance_records_v1';

  Future<List<StudentFinance>> fetchStudentFinances() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataJson = prefs.getString(_financeKey);

    if (dataJson != null) {
      final List<dynamic> decodedList = jsonDecode(dataJson);
      return decodedList.map((item) => StudentFinance.fromJson(item)).toList();
    }

    // Seed data if empty
    final initialData = [
      StudentFinance(studentId: '1001', name: 'Ahmad Hassan', totalFees: 2500.0, paidAmount: 2500.0, installmentsPaid: 5, isBlocked: false),
      StudentFinance(studentId: '1002', name: 'Shilan Azad', totalFees: 2500.0, paidAmount: 1500.0, installmentsPaid: 3, isBlocked: false),
      StudentFinance(studentId: '1003', name: 'Rebwar Ali', totalFees: 2500.0, paidAmount: 0.0, installmentsPaid: 0, isBlocked: true),
    ];

    await prefs.setString(_financeKey, jsonEncode(initialData.map((f) => f.toJson()).toList()));
    return initialData;
  }

  Future<bool> toggleStudentBlockStatus(String studentId, bool currentStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await fetchStudentFinances();
    
    final index = records.indexWhere((r) => r.studentId == studentId);
    if (index != -1) {
      records[index].isBlocked = !currentStatus;
      await prefs.setString(_financeKey, jsonEncode(records.map((f) => f.toJson()).toList()));
      return records[index].isBlocked;
    }
    return !currentStatus;
  }
}