import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_id_card.dart';

class StudentIdCardRepository {
  static const String _studentsKey = 'local_students_v1';

  // Seed data
  static final List<StudentIdCard> _defaultCards = [
    StudentIdCard(id: '1001', name: 'Ahmad Hassan', department: 'Computer Education', course: 'Advanced Java OOP', batch: '2026'),
    StudentIdCard(id: '1002', name: 'Shilan Azad', department: 'Kurdish Literature', course: 'Kurdish Literature & Poetry', batch: '2026'),
    StudentIdCard(id: '1003', name: 'Rebwar Ali', department: 'Software Engineering', course: 'Mobile App Dev (Flutter)', batch: '2026'),
  ];

  Future<List<StudentIdCard>> fetchAllStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataJson = prefs.getString(_studentsKey);

    if (dataJson != null) {
      final List<dynamic> decodedList = jsonDecode(dataJson);
      return decodedList.map((json) => StudentIdCard(
        id: json['id'],
        name: json['name'],
        department: json['department'],
        course: json['course'],
        batch: json['batch'],
      )).toList();
    }

    await _saveDataToDisk(prefs, _defaultCards);
    return _defaultCards;
  }

  Future<StudentIdCard?> findById(String id) async {
    final students = await fetchAllStudents();
    try {
      return students.firstWhere((card) => card.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<StudentIdCard> addStudent({required String name, required String department, required String course, required String batch}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStudents = await fetchAllStudents();
    
    // Generate new ID based on highest existing ID
    final ids = currentStudents.map((c) => int.tryParse(c.id)).whereType<int>();
    final maxId = ids.isEmpty ? 1000 : ids.reduce((a, b) => a > b ? a : b);
    final newId = (maxId + 1).toString();

    final newStudent = StudentIdCard(id: newId, name: name, department: department, course: course, batch: batch);
    currentStudents.add(newStudent);
    
    await _saveDataToDisk(prefs, currentStudents);
    return newStudent;
  }

  Future<void> _saveDataToDisk(SharedPreferences prefs, List<StudentIdCard> students) async {
    final encodedData = jsonEncode(students.map((s) => {
      'id': s.id,
      'name': s.name,
      'department': s.department,
      'course': s.course,
      'batch': s.batch,
    }).toList());
    
    await prefs.setString(_studentsKey, encodedData);
  }
}