import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'edu_nova_school.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_name TEXT,
        course_code TEXT,
        teacher_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE students(
        student_id TEXT PRIMARY KEY,
        first_name TEXT,
        last_name TEXT,
        grade TEXT,
        image_path TEXT,
        fixed_qr_data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE teachers(
        teacher_id TEXT PRIMARY KEY,
        full_name TEXT,
        department TEXT,
        email TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE enrollments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT,
        course_id INTEGER,
        FOREIGN KEY (student_id) REFERENCES students (student_id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE grades(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT,
        course_id INTEGER,
        grade_value TEXT,
        FOREIGN KEY (student_id) REFERENCES students (student_id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        date TEXT,
        total_hours INTEGER,
        is_completed INTEGER DEFAULT 0,
        saved INTEGER DEFAULT 0,
        save_date TEXT,
        department TEXT,
        faculty TEXT,
        academic_year TEXT,
        topic TEXT,
        lecturer_name TEXT,
        last_updated TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        student_id TEXT,
        hour_number INTEGER,
        status TEXT,
        permission_reason TEXT,
        timed_exit_end_time TEXT,
        scanned_in_time TEXT,
        scanned_return_time TEXT,
        is_late_return INTEGER DEFAULT 0,
        manually_modified INTEGER DEFAULT 0,
        modification_reason TEXT,
        notes TEXT,
        FOREIGN KEY (session_id) REFERENCES attendance_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE permission_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        student_id TEXT,
        hour_number INTEGER,
        exit_time TEXT,
        expected_return_time TEXT,
        actual_return_time TEXT,
        status TEXT,
        is_late INTEGER DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES attendance_sessions (id) ON DELETE CASCADE
      )
    ''');

    // NEW: Administrative Request Queue
    await db.execute('''
      CREATE TABLE admin_requests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        requested_by TEXT,
        action_type TEXT,
        target_student_id TEXT,
        target_course_id INTEGER,
        proposed_value TEXT,
        reason TEXT,
        status TEXT DEFAULT 'Pending',
        timestamp TEXT
      )
    ''');
  }

  // ================= SUBJECT & TEACHER METHODS =================

  Future<int> addCourse(String courseName, String courseCode) async {
    Database db = await database;
    try {
      return await db.insert('courses', {'course_name': courseName, 'course_code': courseCode.toUpperCase()});
    } catch (e) {
      return -1;
    }
  }

  Future<List<Course>> getCourses() async {
    Database db = await database;
    var result = await db.query('courses', orderBy: 'course_name');
    return result.map((map) => Course.fromMap(map)).toList();
  }

  Future<void> updateCourse(int courseId, String courseName, String courseCode) async {
    Database db = await database;
    await db.update('courses', {'course_name': courseName, 'course_code': courseCode.toUpperCase()}, where: 'id = ?', whereArgs: [courseId]);
  }

  Future<void> deleteCourse(int courseId) async {
    Database db = await database;
    await db.delete('courses', where: 'id = ?', whereArgs: [courseId]);
  }

  Future<Course?> getCourseByCode(String courseCode) async {
    Database db = await database;
    var results = await db.query('courses', where: 'course_code = ?', whereArgs: [courseCode.toUpperCase()]);
    return results.isNotEmpty ? Course.fromMap(results.first) : null;
  }

  Future<void> addTeacher(String id, String name, String department) async {
    Database db = await database;
    await db.insert('teachers', {'teacher_id': id, 'full_name': name, 'department': department, 'email': '$id@school.edu'}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTeachers() async {
    Database db = await database;
    return await db.query('teachers', orderBy: 'full_name');
  }

  Future<void> assignTeacherToCourse(int courseId, String teacherId) async {
    Database db = await database;
    await db.update('courses', {'teacher_id': teacherId}, where: 'id = ?', whereArgs: [courseId]);
  }

  // ================= STUDENT & GRADE METHODS =================

  Future<Student?> getStudentById(String studentId) async {
    Database db = await database;
    var results = await db.query('students', where: 'student_id = ?', whereArgs: [studentId]);
    return results.isNotEmpty ? Student.fromMap(results.first) : null;
  }

  Future<int> addStudent(Student student) async {
    Database db = await database;
    return await db.insert('students', student.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Student>> getAllStudents() async {
    Database db = await database;
    var result = await db.query('students', orderBy: 'first_name');
    return result.map((map) => Student.fromMap(map)).toList();
  }

  Future<void> deleteStudent(String studentId) async {
    Database db = await database;
    await db.delete('students', where: 'student_id = ?', whereArgs: [studentId]);
  }

  Future<void> enrollStudent(String studentId, int courseId) async {
    Database db = await database;
    try {
      await db.insert('enrollments', {'student_id': studentId, 'course_id': courseId});
    } catch (e) {}
  }

  Future<List<Student>> getStudentsInCourse(int courseId) async {
    Database db = await database;
    var result = await db.rawQuery('''
      SELECT s.* FROM students s
      INNER JOIN enrollments e ON s.student_id = e.student_id
      WHERE e.course_id = ?
      ORDER BY s.first_name
    ''', [courseId]);
    return result.map((map) => Student.fromMap(map)).toList();
  }

  Future<void> updateGrade(String studentId, int courseId, String gradeValue) async {
    Database db = await database;
    var existing = await db.query('grades', where: 'student_id = ? AND course_id = ?', whereArgs: [studentId, courseId]);
    if (existing.isEmpty) {
      await db.insert('grades', {'student_id': studentId, 'course_id': courseId, 'grade_value': gradeValue});
    } else {
      await db.update('grades', {'grade_value': gradeValue}, where: 'student_id = ? AND course_id = ?', whereArgs: [studentId, courseId]);
    }
  }

  Future<String> getStudentGrade(String studentId, int courseId) async {
    Database db = await database;
    var results = await db.query('grades', where: 'student_id = ? AND course_id = ?', whereArgs: [studentId, courseId]);
    return results.isNotEmpty ? results.first['grade_value'].toString() : 'Pending...';
  }

  // ================= LATENCY & ATTENDANCE METHODS =================

  Future<int> createAttendanceSession(int courseId, int totalHours) async {
    Database db = await database;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await db.insert('attendance_sessions', {
      'course_id': courseId, 'date': today, 'total_hours': totalHours, 'last_updated': DateTime.now().toIso8601String()
    });
  }

  Future<void> markAttendance(AttendanceRecord record) async {
    Database db = await database;
    var existing = await db.query('attendance_records', where: 'session_id = ? AND student_id = ? AND hour_number = ?', whereArgs: [record.sessionId, record.studentId, record.hourNumber]);
    if (existing.isEmpty) {
      await db.insert('attendance_records', record.toMap());
    } else {
      await db.update('attendance_records', record.toMap(), where: 'session_id = ? AND student_id = ? AND hour_number = ?', whereArgs: [record.sessionId, record.studentId, record.hourNumber]);
    }
  }

  Future<double> getStudentLatency(String studentId, int courseId) async {
    Database db = await database;
    var sessions = await db.query('attendance_sessions', where: 'course_id = ?', whereArgs: [courseId]);
    if (sessions.isEmpty) return 100.0;

    int totalHoursScanned = 0;
    int attendedHours = 0;

    for (var session in sessions) {
      int sessionId = session['id'] as int;
      int hours = session['total_hours'] as int;
      totalHoursScanned += hours;

      var records = await db.query('attendance_records', where: 'session_id = ? AND student_id = ?', whereArgs: [sessionId, studentId]);
      for (var r in records) {
        if (r['status'] == 'present' || r['status'] == 'permissionEntireHour' || (r['status'] == 'permissionTimed' && r['scanned_return_time'] != null)) {
          attendedHours++;
        }
      }
    }
    return totalHoursScanned == 0 ? 100.0 : (attendedHours / totalHoursScanned) * 100;
  }

  // ================= ADMIN REQUEST QUEUE =================

  Future<void> submitAdminRequest({
    required String requestedBy,
    required String actionType,
    required String targetStudentId,
    required int targetCourseId,
    required String proposedValue,
    required String reason,
  }) async {
    Database db = await database;
    await db.insert('admin_requests', {
      'requested_by': requestedBy,
      'action_type': actionType,
      'target_student_id': targetStudentId,
      'target_course_id': targetCourseId,
      'proposed_value': proposedValue,
      'reason': reason,
      'status': 'Pending',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRequestsBySender(String senderRole) async {
    Database db = await database;
    return await db.query('admin_requests', where: 'requested_by = ?', whereArgs: [senderRole], orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getAllPendingRequests() async {
    Database db = await database;
    return await db.query('admin_requests', where: 'status = ?', whereArgs: ['Pending'], orderBy: 'timestamp ASC');
  }

  Future<void> updateRequestStatus(int requestId, String newStatus) async {
    Database db = await database;
    await db.update('admin_requests', {'status': newStatus}, where: 'id = ?', whereArgs: [requestId]);
  }
}