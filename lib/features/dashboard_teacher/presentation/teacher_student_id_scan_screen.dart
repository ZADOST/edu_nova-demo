import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/models/student_id_card.dart';

class TeacherStudentIdScanScreen extends StatefulWidget {
  final StudentIdCard student;

  const TeacherStudentIdScanScreen({
    super.key,
    required this.student,
  });

  @override
  State<TeacherStudentIdScanScreen> createState() => _TeacherStudentIdScanScreenState();
}

class _TeacherStudentIdScanScreenState extends State<TeacherStudentIdScanScreen> {
  String _selectedAction = 'attended';
  final TextEditingController _reasonController = TextEditingController();
  int _minutesGranted = 5;

  void _handleAction(String? action) {
    if (action == null) return;
    setState(() {
      _selectedAction = action;
    });
  }

  void _submitAction() {
    final message = switch (_selectedAction) {
      'permission' => 'Permission granted for $_minutesGranted minutes.',
      'excused' => 'Student excused: ${_reasonController.text.trim().isEmpty ? 'No reason provided' : _reasonController.text.trim()}',
      _ => 'Student marked as attended.',
    };
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Student Attendance Scan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => context.go('/teacher'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text('Student ID Scan', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: QrImageView(
                      data: widget.student.uniqueCode,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.student.name, style: const TextStyle(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('ID: ${widget.student.uniqueCode}', style: TextStyle(color: AppTheme.mintGlow)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Outcome', style: TextStyle(color: AppTheme.mintGlow, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.darkCharcoal, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedAction,
                        items: const [
                          DropdownMenuItem(value: 'attended', child: Text('Mark Attended', style: TextStyle(color: AppTheme.pureWhite))),
                          DropdownMenuItem(value: 'permission', child: Text('Grant Permission', style: TextStyle(color: AppTheme.pureWhite))),
                          DropdownMenuItem(value: 'excused', child: Text('Excuse Student', style: TextStyle(color: AppTheme.pureWhite))),
                        ],
                        onChanged: _handleAction,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedAction == 'permission')
                    Padding(
                      padding: const EdgeInsets.only(left: 0.0, bottom: 12.0),
                      child: Row(
                        children: [
                          Text('Minutes:', style: TextStyle(color: AppTheme.pureWhite70)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: _minutesGranted.toDouble(),
                              min: 1,
                              max: 60,
                              divisions: 59,
                              activeColor: AppTheme.mintGlow,
                              inactiveColor: AppTheme.pureWhite.withValues(alpha: 0.2),
                              label: '$_minutesGranted min',
                              onChanged: (value) => setState(() => _minutesGranted = value.toInt()),
                            ),
                          ),
                          Text('$_minutesGranted', style: const TextStyle(color: AppTheme.pureWhite)),
                        ],
                      ),
                    ),
                  if (_selectedAction == 'excused')
                    Padding(
                      padding: const EdgeInsets.only(left: 0.0, bottom: 12.0),
                      child: TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        style: const TextStyle(color: AppTheme.pureWhite),
                        decoration: InputDecoration(
                          hintText: 'Enter reason for excusal',
                          hintStyle: TextStyle(color: AppTheme.pureWhite.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: AppTheme.darkCharcoal.withValues(alpha: 0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.mintGlow.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ),
                  if (_selectedAction == 'attended')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Text('Keep the student as present for the session.', style: TextStyle(color: AppTheme.pureWhite70)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/teacher'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.mintGlow.withValues(alpha: 0.6)),
                    ),
                    child: const Text('CANCEL', style: TextStyle(color: AppTheme.mintGlow)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitAction,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGlow),
                    child: const Text('PROCEED', style: TextStyle(color: AppTheme.darkCharcoal)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
