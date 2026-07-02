import 'dart:async';

// Domain Models for the Teacher feature
class SchoolClass {
  final String id;
  final String className;
  final String time;
  final int studentCount;

  SchoolClass({required this.id, required this.className, required this.time, required this.studentCount});
}

class TeacherRepository {
  // Simulating an API call to your MySQL backend
  Future<List<SchoolClass>> fetchTodayClasses() async {
    // Artificial delay to simulate network request
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock Data reflecting regional context (Erbil)
    return [
      SchoolClass(id: 'c1', className: 'Advanced Java OOP', time: '08:30 AM - 10:00 AM', studentCount: 24),
      SchoolClass(id: 'c2', className: 'Kurdish Literature & Poetry', time: '10:30 AM - 12:00 PM', studentCount: 30),
      SchoolClass(id: 'c3', className: 'Mobile App Dev (Flutter)', time: '01:00 PM - 02:30 PM', studentCount: 18),
    ];
  }
}