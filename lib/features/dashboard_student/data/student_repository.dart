import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/student_id_card.dart';

class CourseGrade {
  final String courseName;
  final String grade;

  CourseGrade({required this.courseName, required this.grade});
}

class StudentRepository {
  static const String _studentsKey = 'local_students_v1';
  
  // The courses we want to check against the Teacher's gradebook
  static const List<String> _demoCourses = [
    'Advanced Java OOP',
    'Database Management Systems',
    'Software Engineering Principles',
    'Kurdish Literature & Poetry',
    'Mobile App Dev (Flutter)'
  ];

  Future<StudentIdCard> fetchStudentProfile(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataJson = prefs.getString(_studentsKey);

    if (dataJson != null) {
      final List<dynamic> decodedList = jsonDecode(dataJson);
      try {
        final target = decodedList.firstWhere((json) => json['id'] == studentId);
        return StudentIdCard(
          id: target['id'],
          name: target['name'],
          department: target['department'],
          course: target['course'],
          batch: target['batch'],
        );
      } catch (_) {
        // ID not found in principal's list, proceed to default fallback
      }
    }

    // Default Demo Profile
    return StudentIdCard(
      id: studentId,
      name: 'Shazad Hassan Babakr',
      department: 'Computer Education',
      course: 'Full-Stack & Mobile Dev',
      batch: '2026',
    );
  }

  Future<List<CourseGrade>> fetchMyGrades(String studentName) async {
    final prefs = await SharedPreferences.getInstance();
    List<CourseGrade> myGrades = [];

    // Loop through the courses and read the Teacher's saved gradebook
    for (String course in _demoCourses) {
      final String key = 'local_grades_$course';
      final String? gradesJson = prefs.getString(key);
      
      if (gradesJson != null) {
        final List<dynamic> decodedList = jsonDecode(gradesJson);
        for (var item in decodedList) {
          // If the teacher graded this student, grab it
          if (item['name'] == studentName || studentName.contains(item['name'])) {
            myGrades.add(CourseGrade(courseName: course, grade: item['grade']));
          }
        }
      }
    }

    // If the teacher hasn't published any grades yet, show pending placeholders
    if (myGrades.isEmpty) {
      myGrades = [
        CourseGrade(courseName: 'Advanced Java OOP', grade: 'Pending...'),
        CourseGrade(courseName: 'Mobile App Dev (Flutter)', grade: 'Pending...'),
      ];
    }

    return myGrades;
  }
}