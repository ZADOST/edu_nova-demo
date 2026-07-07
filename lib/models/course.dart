class Course {
  int? id;
  String courseName;
  String courseCode;
  String? teacherId; // Added to fix the 'teacherId' getter error

  Course({
    this.id,
    required this.courseName,
    required this.courseCode,
    this.teacherId,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      courseName: map['course_name'],
      courseCode: map['course_code'],
      teacherId: map['teacher_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_name': courseName,
      'course_code': courseCode,
      'teacher_id': teacherId,
    };
  }
}