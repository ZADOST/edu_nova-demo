class Course {
  final int? id;
  final String courseName;
  final String courseCode; // New field

  Course({
    this.id,
    required this.courseName,
    required this.courseCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'course_name': courseName,
      'course_code': courseCode,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      courseName: map['course_name'],
      courseCode: map['course_code'],
    );
  }
  
  String get displayName => '$courseName - $courseCode';
}