import '../models/student_id_card.dart';

class StudentIdCardRepository {
  static final List<StudentIdCard> sampleCards = [
    StudentIdCard(id: '1001', name: 'Ahmad Hassan', department: 'Computer Education', course: 'Advanced Java OOP', batch: '2026'),
    StudentIdCard(id: '1002', name: 'Shilan Azad', department: 'Kurdish Literature', course: 'Kurdish Literature & Poetry', batch: '2026'),
    StudentIdCard(id: '1003', name: 'Rebwar Ali', department: 'Software Engineering', course: 'Mobile App Dev (Flutter)', batch: '2026'),
  ];

  static StudentIdCard? findById(String id) {
    try {
      return sampleCards.firstWhere((card) => card.id == id);
    } catch (_) {
      return null;
    }
  }

  static String _nextId() {
    final ids = sampleCards.map((c) => int.tryParse(c.id)).whereType<int>();
    final maxId = ids.isEmpty ? 1000 : ids.reduce((a, b) => a > b ? a : b);
    return (maxId + 1).toString();
  }

  static StudentIdCard addStudent({required String name, required String department, required String course, required String batch}) {
    final id = _nextId();
    final student = StudentIdCard(id: id, name: name, department: department, course: course, batch: batch);
    sampleCards.add(student);
    return student;
  }
}
