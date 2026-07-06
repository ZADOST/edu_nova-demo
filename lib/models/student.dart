class Student {
  final int? id;
  final String studentId;
  final String firstName;
  final String lastName;
  final String grade;
  final String? imagePath;
  final String fixedQrData;

  Student({
    this.id,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.grade,
    this.imagePath,
    required this.fixedQrData,
  });

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'first_name': firstName,
      'last_name': lastName,
      'grade': grade,
      'image_path': imagePath,
      'fixed_qr_data': fixedQrData,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      studentId: map['student_id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      grade: map['grade'],
      imagePath: map['image_path'],
      fixedQrData: map['fixed_qr_data'],
    );
  }

  String get fullName => '$firstName $lastName';
}