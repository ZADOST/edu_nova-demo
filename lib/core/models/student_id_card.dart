class StudentIdCard {
  final String id;
  final String name;
  final String department;
  final String course;
  final String batch;

  StudentIdCard({
    required this.id,
    required this.name,
    required this.department,
    required this.course,
    required this.batch,
  });

  String get uniqueCode => 'STU-$id';
}
