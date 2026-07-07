import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// Change the class name below to match the specific file you are creating!
class DeleteCoursePage extends StatelessWidget {
  const DeleteCoursePage({super.key, this.courseId});

  final int? courseId; // Used by ManageStudentsPage

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow), onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(
        child: Text('Under Construction', style: TextStyle(color: AppTheme.mintGlow, fontSize: 24)),
      ),
    );
  }
}