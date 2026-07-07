import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/attendance.dart';

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
  final MobileScannerController _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isProcessing = false;
  Student? _scannedStudent;
  String _statusMessage = 'Position student QR code inside the frame.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.stop();
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() => _isProcessing = true);

    String studentId = rawValue.trim();
    if (studentId.startsWith('STU-')) studentId = studentId.split('STU-').last;

    // Verify student exists in the database
    final student = await _dbHelper.getStudentById(studentId);

    if (student != null) {
      // 1. Play success audio
      try { await _audioPlayer.play(AssetSource('sounds/success.mp3')); } catch (_) {}

      // 2. Save attendance to SQLite
      for (int hour = 1; hour <= widget.totalHours; hour++) {
        await _dbHelper.markAttendance(AttendanceRecord(
          sessionId: widget.sessionId,
          studentId: student.studentId,
          hourNumber: hour,
          status: AttendanceStatus.present,
          scannedInTime: DateTime.now(),
        ));
      }

      // 3. Show Success UI
      setState(() {
        _scannedStudent = student;
        _statusMessage = 'Attendance Recorded!';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _scannedStudent = null;
            _statusMessage = 'Ready for next scan.';
            _isProcessing = false;
          });
        }
      });
    } else {
      // Error UI
      try { await _audioPlayer.play(AssetSource('sounds/error.mp3')); } catch (_) {}
      setState(() {
        _scannedStudent = null;
        _statusMessage = 'Unknown QR Code!';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Active Session Scanner'),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _scannedStudent != null ? AppTheme.mintGlow : Colors.grey.shade800, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: MobileScanner(controller: _controller, onDetect: _handleBarcode),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: _scannedStudent != null ? AppTheme.mintGlow : Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
            if (_scannedStudent != null)
              Positioned(
                bottom: 80, left: 24, right: 24,
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.mintGlow, size: 64),
                      const SizedBox(height: 16),
                      Text(_scannedStudent!.fullName, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}