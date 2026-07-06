import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/data/student_id_card_repository.dart';
import '../../../core/models/student_id_card.dart';

class TeacherStudentQrScannerScreen extends StatefulWidget {
  const TeacherStudentQrScannerScreen({super.key});

  @override
  State<TeacherStudentQrScannerScreen> createState() => _TeacherStudentQrScannerScreenState();
}

class _TeacherStudentQrScannerScreenState extends State<TeacherStudentQrScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StudentIdCardRepository _studentRepo = StudentIdCardRepository();

  bool _isProcessingScan = false;
  StudentIdCard? _scannedStudent;
  String _statusMessage = 'Position the student QR code inside the frame.';

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _playErrorSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessingScan) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() => _isProcessingScan = true);

    final code = rawValue.trim();
    String studentId = code;
    
    if (code.startsWith('STU-')) {
      studentId = code.split('STU-').last;
    }

    // REAL-TIME LOOKUP: Check the database for the student
    final student = await _studentRepo.findById(studentId);

    if (student != null) {
      // SUCCESS: Student Found!
      await _playSuccessSound();
      
      setState(() {
        _scannedStudent = student;
        _statusMessage = 'Attendance Recorded Successfully!';
      });

      // Show the success overlay for 3 seconds, then reset
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _scannedStudent = null;
            _statusMessage = 'Position the next QR code inside the frame.';
            _isProcessingScan = false;
          });
        }
      });
    } else {
      // ERROR: Unknown QR Code
      await _playErrorSound();
      
      setState(() {
        _scannedStudent = null;
        _statusMessage = 'Unknown QR code. Student not found in database.';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessingScan = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Live Attendance Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: AppTheme.mintGlow),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. The Live Camera Feed
            Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _scannedStudent != null ? AppTheme.mintGlow : Colors.grey.shade800, 
                        width: 4
                      ),
                      boxShadow: [
                        if (_scannedStudent != null)
                          BoxShadow(color: AppTheme.mintGlow.withValues(alpha: 0.3), blurRadius: 20)
                      ]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: MobileScanner(
                        controller: _controller,
                        onDetect: _handleBarcode,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      _statusMessage, 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _scannedStudent != null ? AppTheme.mintGlow : AppTheme.pureWhite.withValues(alpha: 0.8), 
                        fontSize: 18,
                        fontWeight: _scannedStudent != null ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                  ),
                ),
              ],
            ),

            // 2. The Dynamic Success Overlay (Mirrors your abduattendancemanager functionality)
            if (_scannedStudent != null)
              Positioned(
                bottom: 80,
                left: 24,
                right: 24,
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.mintGlow, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _scannedStudent!.name,
                        style: const TextStyle(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.deepTeal,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${_scannedStudent!.id} | ${_scannedStudent!.department}',
                          style: const TextStyle(color: AppTheme.pureWhite, fontSize: 14),
                        ),
                      ),
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