import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';

class StudentAttendanceScannerScreen extends StatefulWidget {
  const StudentAttendanceScannerScreen({super.key});

  @override
  State<StudentAttendanceScannerScreen> createState() => _StudentAttendanceScannerScreenState();
}

class _StudentAttendanceScannerScreenState extends State<StudentAttendanceScannerScreen> {
  bool _scanned = false;

  void _toggleScan() {
    setState(() {
      _scanned = !_scanned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        elevation: 0,
        title: const Text('Attendance Scanner'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2, color: AppTheme.mintGlow, size: 120),
                  const SizedBox(height: 24),
                  Text(
                    _scanned ? 'Attendance recorded successfully.' : 'Ready to scan the class attendance QR code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8), fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _toggleScan,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepTeal),
                    child: Text(_scanned ? 'Reset Scanner' : 'Simulate Scan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('How to use', style: TextStyle(color: AppTheme.mintGlow, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 12),
                  Text('This screen simulates the scanner flow until a camera integration is added. Tap the button to mark attendance for the current session.', style: TextStyle(color: AppTheme.pureWhite, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
