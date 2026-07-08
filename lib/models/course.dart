class Course {
  int? id;
  String courseName;
  String courseCode;
  String? teacherId;

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

  // FIX: Added Equality Operators to prevent Dropdown Assertion Red Screens
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id?.hashCode ?? 0;
}