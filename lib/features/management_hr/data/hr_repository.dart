import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StaffMember {
  final String id;
  final String name;
  final String department;
  final String status;
  final bool isWarning;

  StaffMember({
    required this.id,
    required this.name,
    required this.department,
    required this.status,
    this.isWarning = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'status': status,
        'isWarning': isWarning,
      };

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'],
        name: json['name'],
        department: json['department'],
        status: json['status'],
        isWarning: json['isWarning'] ?? false,
      );
}

class HrRepository {
  static const String _staffKey = 'local_hr_staff_v1';

  Future<List<StaffMember>> fetchStaff() async {
    final prefs = await SharedPreferences.getInstance();
    final String? staffJson = prefs.getString(_staffKey);

    if (staffJson != null) {
      final List<dynamic> decodedList = jsonDecode(staffJson);
      return decodedList.map((item) => StaffMember.fromJson(item)).toList();
    }

    // Seed initial mock data reflecting TIU regional context
    final initialStaff = [
      StaffMember(id: 'E001', name: 'Dr. Alan Turing', department: 'Computer Science', status: 'Active'),
      StaffMember(id: 'E002', name: 'Mr. Akar Shwan', department: 'IT Support', status: 'Active'),
      StaffMember(id: 'E003', name: 'Ms. Tara Ahmed', department: 'Accounting', status: 'On Leave', isWarning: true),
      StaffMember(id: 'E004', name: 'Prof. Bakhtyar Ali', department: 'Literature', status: 'Review Pending', isWarning: true),
    ];

    await prefs.setString(_staffKey, jsonEncode(initialStaff.map((s) => s.toJson()).toList()));
    return initialStaff;
  }

  Future<void> addStaffMember(StaffMember newStaff) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStaff = await fetchStaff();
    
    currentStaff.add(newStaff);
    
    await prefs.setString(_staffKey, jsonEncode(currentStaff.map((s) => s.toJson()).toList()));
  }
}