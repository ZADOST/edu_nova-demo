import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../core/models/student.dart';
import '../core/models/course.dart';
import '../core/models/attendance.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbPath = join(documentsDirectory.path, 'attendance.db');
    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Students table
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT UNIQUE,
        first_name TEXT,
        last_name TEXT,
        grade TEXT,
        image_path TEXT,
        fixed_qr_data TEXT UNIQUE
      )
    ''');

    // Courses table with course_code
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_name TEXT,
        course_code TEXT UNIQUE
      )
    ''');

    // Enrollments table
    await db.execute('''
      CREATE TABLE enrollments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT,
        course_id INTEGER,
        UNIQUE(student_id, course_id),
        FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // Attendance sessions table
    await db.execute('''
      CREATE TABLE attendance_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        date TEXT,
        total_hours INTEGER,
        is_completed INTEGER DEFAULT 0,
        last_updated TEXT,
        department TEXT,
        faculty TEXT,
        academic_year TEXT,
        topic TEXT,
        lecturer_name TEXT,
        saved INTEGER DEFAULT 0,
        save_date TEXT,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // Attendance records table
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
        notes TEXT,
        manually_modified INTEGER DEFAULT 0,
        modification_reason TEXT,
        FOREIGN KEY(session_id) REFERENCES attendance_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
        UNIQUE(session_id, student_id, hour_number)
      )
    ''');

    // Permission logs table
    await db.execute('''
      CREATE TABLE permission_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER,
        student_id TEXT,
        hour_number INTEGER,
        exit_time TEXT,
        return_time TEXT,
        expected_return_time TEXT,
        is_late INTEGER DEFAULT 0,
        status TEXT,
        FOREIGN KEY(session_id) REFERENCES attendance_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE permission_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER,
          student_id TEXT,
          hour_number INTEGER,
          exit_time TEXT,
          return_time TEXT,
          expected_return_time TEXT,
          is_late INTEGER DEFAULT 0,
          status TEXT,
          FOREIGN KEY(session_id) REFERENCES attendance_sessions(id) ON DELETE CASCADE,
          FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('ALTER TABLE attendance_sessions ADD COLUMN department TEXT');
      await db.execute('ALTER TABLE attendance_sessions ADD COLUMN faculty TEXT');
      await db.execute('ALTER TABLE attendance_sessions ADD COLUMN academic_year TEXT');
      await db.execute('ALTER TABLE attendance_sessions ADD COLUMN topic TEXT');
      await db.execute('ALTER TABLE attendance_sessions ADD COLUMN lecturer_name TEXT');
    }
    
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE attendance_sessions ADD COLUMN saved INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE attendance_sessions ADD COLUMN save_date TEXT');
      await db.execute('ALTER TABLE attendance_records ADD COLUMN manually_modified INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE attendance_records ADD COLUMN modification_reason TEXT');
    }
    
    if (oldVersion < 4) {
      try {
        // Add course_code column to courses table
        await db.execute('ALTER TABLE courses ADD COLUMN course_code TEXT DEFAULT ""');
        
        // Update existing courses - set course_code = course_name for existing data
        await db.execute('UPDATE courses SET course_code = course_name WHERE course_code = "" OR course_code IS NULL');
        
        // Check if there are any duplicate course_code values
        var duplicates = await db.rawQuery('''
          SELECT course_code, COUNT(*) as cnt 
          FROM courses 
          GROUP BY course_code 
          HAVING cnt > 1
        ''');
        
        if (duplicates.isNotEmpty) {
          // If there are duplicates, make them unique by appending id
          var allCourses = await db.query('courses');
          for (var course in allCourses) {
            int id = course['id'] as int;
            String originalCode = course['course_code'] as String;
            String uniqueCode = '$originalCode-$id';
            await db.update(
              'courses',
              {'course_code': uniqueCode},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
        
        // Create new table with UNIQUE constraint
        await db.execute('''
          CREATE TABLE courses_new(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            course_name TEXT,
            course_code TEXT UNIQUE
          )
        ''');
        
        // Copy data
        await db.execute('''
          INSERT INTO courses_new(id, course_name, course_code)
          SELECT id, course_name, course_code FROM courses
        ''');
        
        // Drop old table
        await db.execute('DROP TABLE courses');
        
        // Rename new table
        await db.execute('ALTER TABLE courses_new RENAME TO courses');
        
      } catch (e) {
        debugPrint('Migration error: $e');
        // If migration fails, try simpler approach
        try {
          await db.execute('ALTER TABLE courses ADD COLUMN course_code TEXT');
          await db.execute('UPDATE courses SET course_code = course_name WHERE course_code IS NULL');
        } catch (e2) {
          debugPrint('Fallback migration error: $e2');
        }
      }
    }
  }

  // ========== COURSE METHODS ==========
  Future<int> addCourse(String courseName, String courseCode) async {
    Database db = await database;
    try {
      return await db.insert('courses', {
        'course_name': courseName,
        'course_code': courseCode.toUpperCase(),
      });
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
    await db.update(
      'courses',
      {
        'course_name': courseName,
        'course_code': courseCode.toUpperCase(),
      },
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  Future<void> deleteCourse(int courseId) async {
    Database db = await database;
    await db.delete('courses', where: 'id = ?', whereArgs: [courseId]);
  }

  Future<Map<String, dynamic>?> getCourseById(int courseId) async {
    Database db = await database;
    var results = await db.query('courses', where: 'id = ?', whereArgs: [courseId]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<Course?> getCourseByCode(String courseCode) async {
    Database db = await database;
    var results = await db.query('courses', where: 'course_code = ?', whereArgs: [courseCode.toUpperCase()]);
    return results.isNotEmpty ? Course.fromMap(results.first) : null;
  }

  // ========== STUDENT METHODS ==========
  Future<Student?> getStudentById(String studentId) async {
    Database db = await database;
    var results = await db.query(
      'students',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return results.isNotEmpty ? Student.fromMap(results.first) : null;
  }

  Future<int> addStudent(Student student) async {
    Database db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<void> updateStudent(String studentId, Map<String, dynamic> data) async {
    Database db = await database;
    await db.update(
      'students',
      data,
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
  }

  Future<void> deleteStudent(String studentId) async {
    Database db = await database;
    
    var student = await getStudentById(studentId);
    
    await db.delete('students', where: 'student_id = ?', whereArgs: [studentId]);
    
    if (student != null && student.imagePath != null) {
      try {
        File imageFile = File(student.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
          debugPrint('✅ Deleted image for student: $studentId');
        }
      } catch (e) {
        debugPrint('Error deleting image file: $e');
      }
    }
  }

  Future<List<Student>> getAllStudents() async {
    Database db = await database;
    var result = await db.query('students', orderBy: 'first_name');
    return result.map((map) => Student.fromMap(map)).toList();
  }

  // ========== ENROLLMENT METHODS ==========
  Future<void> enrollStudent(String studentId, int courseId) async {
    Database db = await database;
    try {
      await db.insert('enrollments', {
        'student_id': studentId,
        'course_id': courseId,
      });
    } catch (e) {
      // Duplicate enrollment, ignore
    }
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

  Future<void> removeStudentFromCourse(String studentId, int courseId) async {
    Database db = await database;
    await db.delete(
      'enrollments',
      where: 'student_id = ? AND course_id = ?',
      whereArgs: [studentId, courseId],
    );
  }

  // ========== ATTENDANCE SESSION METHODS ==========
  Future<int> createAttendanceSession(int courseId, int totalHours) async {
    Database db = await database;
    
    await _clearOldIncompleteSessions(db);
    
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await db.insert('attendance_sessions', {
      'course_id': courseId,
      'date': today,
      'total_hours': totalHours,
      'is_completed': 0,
      'last_updated': DateTime.now().toIso8601String(),
      'saved': 0,
    });
  }

  Future<void> _clearOldIncompleteSessions(Database db) async {
    var latest = await db.query(
      'attendance_sessions',
      where: 'is_completed = 0',
      orderBy: 'last_updated DESC',
      limit: 1,
    );
    
    if (latest.isNotEmpty) {
      int latestId = latest.first['id'] as int;
      
      await db.delete(
        'attendance_sessions',
        where: 'is_completed = 0 AND id != ?',
        whereArgs: [latestId],
      );
    }
  }

  Future<void> updateSessionDetails(int sessionId, {
    required String department,
    required String faculty,
    required String academicYear,
    required String topic,
    required String lecturerName,
  }) async {
    Database db = await database;
    await db.update(
      'attendance_sessions',
      {
        'department': department,
        'faculty': faculty,
        'academic_year': academicYear,
        'topic': topic,
        'lecturer_name': lecturerName,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> saveAttendanceSession(int sessionId) async {
    Database db = await database;
    await db.update(
      'attendance_sessions',
      {
        'saved': 1,
        'save_date': DateTime.now().toIso8601String(),
        'is_completed': 1,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> completeSession(int sessionId) async {
    Database db = await database;
    await db.update(
      'attendance_sessions',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<AttendanceSession?> getIncompleteSession() async {
    Database db = await database;
    var results = await db.query(
      'attendance_sessions',
      where: 'is_completed = 0',
      orderBy: 'last_updated DESC',
      limit: 1,
    );
    return results.isNotEmpty ? AttendanceSession.fromMap(results.first) : null;
  }

  Future<List<Map<String, dynamic>>> getSavedSessions(int courseId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT s.*, c.course_code, c.course_name 
      FROM attendance_sessions s
      INNER JOIN courses c ON s.course_id = c.id
      WHERE s.course_id = ? AND s.saved = 1
      ORDER BY s.save_date DESC
    ''', [courseId]);
  }

  Future<Map<String, dynamic>?> getSessionDetails(int sessionId) async {
    Database db = await database;
    var results = await db.rawQuery('''
      SELECT s.*, c.course_code, c.course_name
      FROM attendance_sessions s
      INNER JOIN courses c ON s.course_id = c.id
      WHERE s.id = ?
    ''', [sessionId]);
    return results.isNotEmpty ? results.first : null;
  }

  // ========== ATTENDANCE RECORD METHODS ==========
  Future<void> markAttendance(AttendanceRecord record) async {
    Database db = await database;
    
    var existing = await db.query(
      'attendance_records',
      where: 'session_id = ? AND student_id = ? AND hour_number = ?',
      whereArgs: [record.sessionId, record.studentId, record.hourNumber],
    );

    if (existing.isEmpty) {
      await db.insert('attendance_records', record.toMap());
    } else {
      await db.update(
        'attendance_records',
        record.toMap(),
        where: 'session_id = ? AND student_id = ? AND hour_number = ?',
        whereArgs: [record.sessionId, record.studentId, record.hourNumber],
      );
    }

    await db.update(
      'attendance_sessions',
      {'last_updated': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [record.sessionId],
    );
  }

  Future<void> manuallyUpdateAttendance({
    required int sessionId,
    required String studentId,
    required int hourNumber,
    required String status,
    String? reason,
  }) async {
    Database db = await database;
    
    var existing = await db.query(
      'attendance_records',
      where: 'session_id = ? AND student_id = ? AND hour_number = ?',
      whereArgs: [sessionId, studentId, hourNumber],
    );

    Map<String, dynamic> recordData = {
      'session_id': sessionId,
      'student_id': studentId,
      'hour_number': hourNumber,
      'status': status,
      'manually_modified': 1,
      'modification_reason': reason,
    };

    if (existing.isEmpty) {
      await db.insert('attendance_records', recordData);
    } else {
      await db.update(
        'attendance_records',
        recordData,
        where: 'session_id = ? AND student_id = ? AND hour_number = ?',
        whereArgs: [sessionId, studentId, hourNumber],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceWithDetails(
    int sessionId, 
    int hourNumber
  ) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT ar.*, s.first_name, s.last_name, s.grade, s.image_path
      FROM attendance_records ar
      INNER JOIN students s ON ar.student_id = s.student_id
      WHERE ar.session_id = ? AND ar.hour_number = ?
    ''', [sessionId, hourNumber]);
  }

  // ========== PERMISSION LOG METHODS ==========
  Future<void> logPermission({
    required int sessionId,
    required String studentId,
    required int hourNumber,
    required DateTime exitTime,
    required DateTime expectedReturnTime,
    DateTime? returnTime,
    bool isLate = false,
    String status = 'pending',
  }) async {
    Database db = await database;
    await db.insert('permission_logs', {
      'session_id': sessionId,
      'student_id': studentId,
      'hour_number': hourNumber,
      'exit_time': exitTime.toIso8601String(),
      'return_time': returnTime?.toIso8601String(),
      'expected_return_time': expectedReturnTime.toIso8601String(),
      'is_late': isLate ? 1 : 0,
      'status': status,
    });
  }

  Future<void> updatePermissionReturn(int sessionId, String studentId, int hourNumber, DateTime returnTime) async {
    Database db = await database;
    var log = await db.query(
      'permission_logs',
      where: 'session_id = ? AND student_id = ? AND hour_number = ?',
      whereArgs: [sessionId, studentId, hourNumber],
    );
    
    if (log.isNotEmpty) {
      DateTime expected = DateTime.parse(log.first['expected_return_time'] as String);
      bool isLate = returnTime.isAfter(expected);
      
      await db.update(
        'permission_logs',
        {
          'return_time': returnTime.toIso8601String(),
          'status': 'returned',
          'is_late': isLate ? 1 : 0,
        },
        where: 'session_id = ? AND student_id = ? AND hour_number = ?',
        whereArgs: [sessionId, studentId, hourNumber],
      );
    }
  }

  Future<void> markPermissionNotReturned(int sessionId, String studentId, int hourNumber) async {
    Database db = await database;
    await db.update(
      'permission_logs',
      {'status': 'not_returned'},
      where: 'session_id = ? AND student_id = ? AND hour_number = ?',
      whereArgs: [sessionId, studentId, hourNumber],
    );
  }

  // ========== REPORT METHODS ==========
  Future<List<Map<String, dynamic>>> getFullAttendanceReport(int sessionId) async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        s.student_id,
        s.first_name,
        s.last_name,
        s.grade,
        ar.hour_number,
        ar.status,
        ar.permission_reason,
        ar.scanned_in_time,
        ar.scanned_return_time,
        ar.is_late_return,
        ar.notes,
        ar.manually_modified,
        ar.modification_reason,
        pl.exit_time,
        pl.return_time as perm_return_time,
        pl.expected_return_time,
        pl.is_late as perm_is_late,
        pl.status as perm_status
      FROM students s
      INNER JOIN enrollments e ON s.student_id = e.student_id
      LEFT JOIN attendance_records ar ON s.student_id = ar.student_id AND ar.session_id = ?
      LEFT JOIN permission_logs pl ON s.student_id = pl.student_id AND pl.session_id = ? AND pl.hour_number = ar.hour_number
      WHERE e.course_id = (SELECT course_id FROM attendance_sessions WHERE id = ?)
      ORDER BY s.first_name, ar.hour_number
    ''', [sessionId, sessionId, sessionId]);
  }

  Future<Map<String, dynamic>> getSessionReport(int sessionId) async {
    Database db = await database;
    var session = await db.rawQuery('''
      SELECT s.*, c.course_code, c.course_name
      FROM attendance_sessions s
      INNER JOIN courses c ON s.course_id = c.id
      WHERE s.id = ?
    ''', [sessionId]);
    
    return {
      'session': session.first,
      'course': {'course_name': session.first['course_name'], 'course_code': session.first['course_code']},
    };
  }

  // ========== DELETE METHODS FOR ATTENDANCE RECORDS ==========
  Future<int> deleteSelectedSessions(List<int> sessionIds) async {
    Database db = await database;
    int count = 0;
    
    for (int sessionId in sessionIds) {
      int rowsAffected = await db.delete(
        'attendance_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      if (rowsAffected > 0) count++;
    }
    
    return count;
  }

  Future<int> deleteAllSessionsForCourse(int courseId) async {
    Database db = await database;
    
    var sessions = await db.query(
      'attendance_sessions',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    
    int count = 0;
    for (var session in sessions) {
      int sessionId = session['id'] as int;
      int rowsAffected = await db.delete(
        'attendance_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      if (rowsAffected > 0) count++;
    }
    
    return count;
  }

  Future<int> deleteAllSessions() async {
    Database db = await database;
    
    var sessions = await db.query('attendance_sessions');
    int count = sessions.length;
    
    await db.delete('attendance_sessions');
    
    return count;
  }

  Future<int> deleteAllIncompleteSessions() async {
    Database db = await database;
    
    var sessions = await db.query(
      'attendance_sessions',
      where: 'is_completed = 0',
    );
    int count = sessions.length;
    
    await db.delete(
      'attendance_sessions',
      where: 'is_completed = 0',
    );
    
    return count;
  }

  // ========== UTILITY METHODS ==========
  Future<void> deleteImageFile(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        debugPrint('✅ Deleted image file: $imagePath');
      }
    } catch (e) {
      debugPrint('Error deleting image file: $e');
    }
  }
}