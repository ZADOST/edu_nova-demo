import 'package:intl/intl.dart';

enum AttendanceStatus {
  present,
  absent,
  permissionEntireHour,
  permissionTimed,
}

class AttendanceRecord {
  final int? id;
  final int sessionId;
  final String studentId;
  final int hourNumber;
  final AttendanceStatus status;
  final String? permissionReason;
  final DateTime? timedExitEndTime;
  final DateTime? scannedInTime;
  final DateTime? scannedReturnTime;
  final bool isLateReturn;
  final String? notes;

  AttendanceRecord({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.hourNumber,
    required this.status,
    this.permissionReason,
    this.timedExitEndTime,
    this.scannedInTime,
    this.scannedReturnTime,
    this.isLateReturn = false,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'student_id': studentId,
      'hour_number': hourNumber,
      'status': status.name,
      'permission_reason': permissionReason,
      'timed_exit_end_time': timedExitEndTime?.toIso8601String(),
      'scanned_in_time': scannedInTime?.toIso8601String(),
      'scanned_return_time': scannedReturnTime?.toIso8601String(),
      'is_late_return': isLateReturn ? 1 : 0,
      'notes': notes,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      sessionId: map['session_id'],
      studentId: map['student_id'],
      hourNumber: map['hour_number'],
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      permissionReason: map['permission_reason'],
      timedExitEndTime: map['timed_exit_end_time'] != null
          ? DateTime.parse(map['timed_exit_end_time'])
          : null,
      scannedInTime: map['scanned_in_time'] != null
          ? DateTime.parse(map['scanned_in_time'])
          : null,
      scannedReturnTime: map['scanned_return_time'] != null
          ? DateTime.parse(map['scanned_return_time'])
          : null,
      isLateReturn: map['is_late_return'] == 1,
      notes: map['notes'],
    );
  }
}

class AttendanceSession {
  final int? id;
  final int courseId;
  final DateTime date;
  final int totalHours;
  final bool isCompleted;
  final DateTime lastUpdated;

  AttendanceSession({
    this.id,
    required this.courseId,
    required this.date,
    required this.totalHours,
    required this.isCompleted,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'course_id': courseId,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'total_hours': totalHours,
      'is_completed': isCompleted ? 1 : 0,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      id: map['id'],
      courseId: map['course_id'],
      date: DateTime.parse(map['date']),
      totalHours: map['total_hours'],
      isCompleted: map['is_completed'] == 1,
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }
}