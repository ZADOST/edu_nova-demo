import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';

class TeacherStudentQrScannerScreen extends StatefulWidget {
  const TeacherStudentQrScannerScreen({super.key});

  @override
  State<TeacherStudentQrScannerScreen> createState() => _TeacherStudentQrScannerScreenState();
}

class _TeacherStudentQrScannerScreenState extends State<TeacherStudentQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  String _statusMessage = 'Position the student QR code inside the frame.';

  void _handleDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() => _hasScanned = true);

    final code = rawValue.trim();

    if (code.startsWith('STU-')) {
      final studentId = code.split('STU-').last;
      if (studentId.isNotEmpty) {
        if (context.mounted) {
          context.go('/teacher/student-scan?id=$studentId');
        }
        return;
      }
    }

    setState(() {
      _statusMessage = 'Unknown QR code. Please scan a valid student ID card.';
      _hasScanned = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('QR Student Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => context.go('/teacher'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: AppTheme.mintGlow),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 420,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: MobileScanner(
                        controller: _controller,
                        onDetect: _handleDetect,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(_statusMessage, style: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.8), fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasScanned = false;
                        _statusMessage = 'Position the student QR code inside the frame.';
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepTeal),
                    child: const Text('RESET SCANNER'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}