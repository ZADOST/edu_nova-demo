import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Domain Models for the Teacher feature
class SchoolClass {
  final String id;
  final String className;
  final String time;
  final int studentCount;

  SchoolClass({
    required this.id, 
    required this.className, 
    required this.time, 
    required this.studentCount
  });

  // Convert object to JSON for local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'className': className,
    'time': time,
    'studentCount': studentCount,
  };

  // Create object from locally stored JSON
  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
    id: json['id'],
    className: json['className'],
    time: json['time'],
    studentCount: json['studentCount'],
  );
}

class StudentGrade {
  final String name;
  String grade;

  StudentGrade({required this.name, required this.grade});

  Map<String, dynamic> toJson() => {
    'name': name,
    'grade': grade,
  };

  factory StudentGrade.fromJson(Map<String, dynamic> json) => StudentGrade(
    name: json['name'],
    grade: json['grade'],
  );
}

class TeacherRepository {
  static const String _classesKey = 'local_teacher_classes';
  static const String _gradesPrefix = 'local_grades_';

  // Fetch from SharedPreferences instead of MySQL
  Future<List<SchoolClass>> fetchTodayClasses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? classesJson = prefs.getString(_classesKey);

    // If data exists locally, parse it and return
    if (classesJson != null) {
      final List<dynamic> decodedList = jsonDecode(classesJson);
      return decodedList.map((item) => SchoolClass.fromJson(item)).toList();
    }

    // Seed initial mock data reflecting regional context (Erbil) if empty
    final initialClasses = [
      SchoolClass(id: 'c1', className: 'Advanced Java OOP', time: '08:30 AM - 10:00 AM', studentCount: 24),
      SchoolClass(id: 'c2', className: 'Kurdish Literature & Poetry', time: '10:30 AM - 12:00 PM', studentCount: 30),
      SchoolClass(id: 'c3', className: 'Mobile App Dev (Flutter)', time: '01:00 PM - 02:30 PM', studentCount: 18),
    ];

    // Save the seed data to preferences so it persists
    await prefs.setString(_classesKey, jsonEncode(initialClasses.map((c) => c.toJson()).toList()));
    
    return initialClasses;
  }

  // Save updated grades securely to local device storage
  Future<void> saveGrades(String course, List<StudentGrade> students) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_gradesPrefix$course';
    
    final String encodedData = jsonEncode(students.map((s) => s.toJson()).toList());
    await prefs.setString(key, encodedData);
  }

  // Retrieve saved grades across app restarts
  Future<List<StudentGrade>> fetchSavedGradesForCourse(String course) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_gradesPrefix$course';
    final String? gradesJson = prefs.getString(key);

    if (gradesJson != null) {
      final List<dynamic> decodedList = jsonDecode(gradesJson);
      return decodedList.map((item) => StudentGrade.fromJson(item)).toList();
    }

    return [];
  }
}