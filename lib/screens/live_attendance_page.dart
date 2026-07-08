import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import 'attendance_sheet_page.dart';

class TimerInfo {
  final DateTime endTime;
  final Student student;
  TimerInfo({required this.endTime, required this.student});
}

class LiveAttendancePage extends StatefulWidget {
  final int sessionId;
  final int courseId;
  final int totalHours;

  const LiveAttendancePage({
    super.key,
    required this.sessionId,
    required this.courseId,
    required this.totalHours,
  });

  @override
  State<LiveAttendancePage> createState() => _LiveAttendancePageState();
}

class _LiveAttendancePageState extends State<LiveAttendancePage> with WidgetsBindingObserver {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final AudioPlayer _audioPlayer = AudioPlayer();
  MobileScannerController? scannerController;
  
  int currentHour = 1;
  List<Student> students = [];
  Map<String, AttendanceRecord> attendanceMap = {};
  Map<String, TimerInfo> activeTimers = {};
  
  Student? currentScannedStudent;
  bool isCameraActive = false;
  bool isProcessingScan = false;
  bool isDialogOpen = false;
  
  DateTime? lastTapTime;
  Student? lastTappedStudent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStudents();
    _loadExistingAttendance();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (scannerController != null) {
      scannerController!.stop();
      scannerController!.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    scannerController = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
    setState(() => isCameraActive = true);
    await scannerController!.start();
  }

  Future<void> _toggleCamera() async {
    if (isCameraActive) {
      await scannerController?.stop();
      setState(() => isCameraActive = false);
    } else {
      if (scannerController == null) {
        await _initCamera();
      } else {
        await scannerController!.start();
        setState(() => isCameraActive = true);
      }
    }
  }

  Future<void> _loadStudents() async {
    var data = await dbHelper.getStudentsInCourse(widget.courseId);
    setState(() => students = data);
  }

  Future<void> _loadExistingAttendance() async {
    final db = await dbHelper.database;
    var records = await db.query('attendance_records', where: 'session_id = ? AND hour_number = ?', whereArgs: [widget.sessionId, currentHour]);
    setState(() {
      attendanceMap.clear();
      for (var record in records) {
        String studentId = record['student_id'] as String;
        attendanceMap[studentId] = AttendanceRecord.fromMap(record);
      }
    });
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (!isCameraActive || isProcessingScan || isDialogOpen || capture.barcodes.isEmpty) return;

    setState(() => isProcessingScan = true);
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) {
      setState(() => isProcessingScan = false);
      return;
    }

    String studentId = rawValue.trim();
    if (studentId.startsWith('STU-')) studentId = studentId.split('STU-').last;

    try {
      final student = students.firstWhere((s) => s.studentId == studentId || s.fixedQrData == rawValue.trim());
      await _processScannedStudent(student);
    } catch (e) {
      if (mounted && !isDialogOpen) {
        try { await _audioPlayer.play(AssetSource('sounds/error.mp3')); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student not enrolled in this subject'), backgroundColor: Colors.red));
      }
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => isProcessingScan = false);
    });
  }

  Future<void> _processScannedStudent(Student student) async {
    if (activeTimers.containsKey(student.studentId)) {
      await _handleReturnScan(student);
      return;
    }

    if (attendanceMap.containsKey(student.studentId)) {
      var existingRecord = attendanceMap[student.studentId];
      if (existingRecord?.status == AttendanceStatus.present) {
        _showPermissionOptions(student);
        return;
      }
      if (existingRecord?.status == AttendanceStatus.permissionTimed) {
        await _handleReturnScan(student);
        return;
      }
    } else {
      await _markPresent(student);
    }
  }

  Future<void> _markPresent(Student student) async {
    AttendanceRecord record = AttendanceRecord(
      sessionId: widget.sessionId,
      studentId: student.studentId,
      hourNumber: currentHour,
      status: AttendanceStatus.present,
      scannedInTime: DateTime.now(),
    );
    
    await dbHelper.markAttendance(record);
    try { await _audioPlayer.play(AssetSource('sounds/success.mp3')); } catch (_) {}
    
    setState(() {
      attendanceMap[student.studentId] = record;
      currentScannedStudent = student;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && currentScannedStudent?.studentId == student.studentId) {
        setState(() => currentScannedStudent = null);
      }
    });
  }

  void _showPermissionOptions(Student student) {
    setState(() => isDialogOpen = true);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCharcoal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(student.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Already present. Select action:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.orangeAccent),
              title: const Text('Timed Break', style: TextStyle(color: AppTheme.pureWhite)),
              onTap: () { Navigator.pop(context); _showTimedPermissionDialog(student); },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text('Excuse for Rest of Hour', style: TextStyle(color: AppTheme.pureWhite)),
              onTap: () { Navigator.pop(context); _showFullHourPermissionDialog(student); },
            ),
          ],
        ),
      ),
    ).then((_) => setState(() => isDialogOpen = false));
  }

  void _showTimedPermissionDialog(Student student) {
    setState(() => isDialogOpen = true);
    int minutes = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkCharcoal,
          title: const Text('Timed Permission', style: TextStyle(color: AppTheme.pureWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Minutes for ${student.firstName}:', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.mintGlow), onPressed: () => setDialogState(() { if (minutes > 1) minutes--; })),
                  Text('$minutes min', style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.mintGlow), onPressed: () => setDialogState(() => minutes++)),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
              onPressed: () async {
                Navigator.pop(context);
                DateTime endTime = DateTime.now().add(Duration(minutes: minutes));
                
                AttendanceRecord record = AttendanceRecord(
                  sessionId: widget.sessionId,
                  studentId: student.studentId,
                  hourNumber: currentHour,
                  status: AttendanceStatus.permissionTimed,
                  timedExitEndTime: endTime,
                  scannedInTime: DateTime.now(),
                );
                await dbHelper.markAttendance(record);
                
                setState(() {
                  attendanceMap[student.studentId] = record;
                  activeTimers[student.studentId] = TimerInfo(endTime: endTime, student: student);
                });
                _startTimerCheck(student, endTime);
              },
              child: const Text('START TIMER', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    ).then((_) => setState(() => isDialogOpen = false));
  }

  void _showFullHourPermissionDialog(Student student) {
    setState(() => isDialogOpen = true);
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Excuse Student', style: TextStyle(color: AppTheme.pureWhite)),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(color: AppTheme.pureWhite),
          decoration: const InputDecoration(labelText: 'Reason (Optional)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            onPressed: () async {
              Navigator.pop(context);
              AttendanceRecord record = AttendanceRecord(
                sessionId: widget.sessionId,
                studentId: student.studentId,
                hourNumber: currentHour,
                status: AttendanceStatus.permissionEntireHour,
                permissionReason: reasonCtrl.text,
                scannedInTime: DateTime.now(),
              );
              await dbHelper.markAttendance(record);
              setState(() => attendanceMap[student.studentId] = record);
            },
            child: const Text('SAVE', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ).then((_) => setState(() => isDialogOpen = false));
  }

  void _startTimerCheck(Student student, DateTime endTime) {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !activeTimers.containsKey(student.studentId)) return;
      if (currentHour != attendanceMap[student.studentId]?.hourNumber) {
        setState(() => activeTimers.remove(student.studentId));
        return;
      }

      if (DateTime.now().isAfter(endTime)) {
        _showReturnDialog(student);
      } else {
        _startTimerCheck(student, endTime);
      }
    });
  }

  void _showReturnDialog(Student student) {
    if (isDialogOpen) return;
    setState(() => isDialogOpen = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Timer Expired!', style: TextStyle(color: Colors.redAccent)),
        content: Text('Did ${student.firstName} return?', style: const TextStyle(color: AppTheme.pureWhite)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleNoReturn(student);
            },
            child: const Text('NO, MARK ABSENT', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            onPressed: () {
              Navigator.pop(context);
              setState(() => isDialogOpen = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please scan ${student.firstName} to confirm return')));
            },
            child: const Text('YES, SCAN NOW', style: TextStyle(color: AppTheme.darkCharcoal)),
          )
        ],
      ),
    ).then((_) => setState(() => isDialogOpen = false));
  }

  Future<void> _handleReturnScan(Student student) async {
    TimerInfo timerInfo = activeTimers[student.studentId]!;
    bool isLate = DateTime.now().isAfter(timerInfo.endTime);
    
    AttendanceRecord record = AttendanceRecord(
      sessionId: widget.sessionId,
      studentId: student.studentId,
      hourNumber: currentHour,
      status: AttendanceStatus.present,
      scannedInTime: attendanceMap[student.studentId]?.scannedInTime,
      scannedReturnTime: DateTime.now(),
      isLateReturn: isLate,
    );
    
    await dbHelper.markAttendance(record);
    try { await _audioPlayer.play(AssetSource('sounds/success.mp3')); } catch (_) {}
    
    setState(() {
      attendanceMap[student.studentId] = record;
      activeTimers.remove(student.studentId);
      currentScannedStudent = student;
    });

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isLate ? '${student.firstName} returned LATE' : 'Returned on time'), backgroundColor: isLate ? Colors.orange : Colors.green));
    Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => currentScannedStudent = null); });
  }

  Future<void> _handleNoReturn(Student student) async {
    AttendanceRecord record = AttendanceRecord(
      sessionId: widget.sessionId,
      studentId: student.studentId,
      hourNumber: currentHour,
      status: AttendanceStatus.absent,
      notes: 'Did not return from break',
    );
    await dbHelper.markAttendance(record);
    setState(() {
      attendanceMap[student.studentId] = record;
      activeTimers.remove(student.studentId);
    });
  }

  void _handleStudentDoubleTap(Student student) {
    final now = DateTime.now();
    if (lastTappedStudent?.studentId == student.studentId && lastTapTime != null && now.difference(lastTapTime!) < const Duration(milliseconds: 500)) {
      _showManualAttendanceDialog(student);
    }
    lastTapTime = now;
    lastTappedStudent = student;
  }

  void _showManualAttendanceDialog(Student student) {
    String selectedStatus = 'present';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkCharcoal,
          title: Text('Manual Override: ${student.firstName}', style: const TextStyle(color: AppTheme.pureWhite)),
          content: DropdownButton<String>(
            value: selectedStatus,
            dropdownColor: AppTheme.darkCharcoal,
            isExpanded: true,
            style: const TextStyle(color: AppTheme.pureWhite),
            items: const [
              DropdownMenuItem(value: 'present', child: Text('Present')),
              DropdownMenuItem(value: 'absent', child: Text('Absent')),
              DropdownMenuItem(value: 'permissionEntireHour', child: Text('Excused')),
            ],
            onChanged: (val) => setState(() => selectedStatus = val!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
              onPressed: () async {
                Navigator.pop(context);
                final db = await dbHelper.database;
                await db.execute('''
                  INSERT OR REPLACE INTO attendance_records (session_id, student_id, hour_number, status, manually_modified) 
                  VALUES (?, ?, ?, ?, 1)
                ''', [widget.sessionId, student.studentId, currentHour, selectedStatus]);
                await _loadExistingAttendance();
              },
              child: const Text('SAVE', style: TextStyle(color: AppTheme.darkCharcoal)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _nextHour() async {
    if (activeTimers.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resolve pending break timers before advancing.'), backgroundColor: Colors.orange));
      return;
    }

    if (currentHour < widget.totalHours) {
      setState(() {
        currentHour++;
        currentScannedStudent = null;
      });
      await _loadExistingAttendance();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final topicCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Complete Session', style: TextStyle(color: AppTheme.pureWhite)),
        content: TextField(
          controller: topicCtrl,
          style: const TextStyle(color: AppTheme.pureWhite),
          decoration: const InputDecoration(labelText: 'Topic Covered (Optional)', labelStyle: TextStyle(color: AppTheme.mintGlow)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
            onPressed: () async {
              Navigator.pop(context);
              final db = await dbHelper.database;
              await db.update('attendance_sessions', {'is_completed': 1, 'topic': topicCtrl.text, 'saved': 1, 'save_date': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [widget.sessionId]);
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AttendanceSheetPage(sessionId: widget.sessionId)));
              }
            },
            child: const Text('FINISH & VIEW PDF', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(Student student) {
    var record = attendanceMap[student.studentId];
    if (record == null) return Colors.redAccent;
    if (record.status == AttendanceStatus.present) return Colors.greenAccent;
    if (record.status == AttendanceStatus.permissionTimed || record.status == AttendanceStatus.permissionEntireHour) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    int presentCount = attendanceMap.values.where((r) => r.status == AttendanceStatus.present).length;
    
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: Text('Hour $currentHour of ${widget.totalHours}', style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow), onPressed: () => Navigator.pop(context)),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.deepTeal.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
            child: Text('$presentCount / ${students.length}', style: const TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isCameraActive && scannerController != null)
              Container(
                height: 250,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.mintGlow, width: 2)),
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: MobileScanner(controller: scannerController!, onDetect: _handleBarcode)),
              )
            else
              Container(
                height: 100,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.deepTeal.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _toggleCamera,
                    icon: const Icon(Icons.videocam, color: AppTheme.darkCharcoal),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
                    label: const Text('ACTIVATE CAMERA', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

            if (currentScannedStudent != null)
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                    const SizedBox(width: 16),
                    Text(currentScannedStudent!.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final statusColor = _getStatusColor(student);
                  
                  return GestureDetector(
                    onTap: () => _handleStudentDoubleTap(student),
                    child: GlassContainer(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(student.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                          Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nextHour,
        backgroundColor: AppTheme.mintGlow,
        label: Text(currentHour < widget.totalHours ? 'NEXT HOUR' : 'COMPLETE', style: const TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold)),
        icon: Icon(currentHour < widget.totalHours ? Icons.navigate_next : Icons.done_all, color: AppTheme.darkCharcoal),
      ),
    );
  }
}