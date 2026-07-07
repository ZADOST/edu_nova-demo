import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/glass_container.dart';
import '../database/database_helper.dart';
import '../models/student.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isProcessing = false;
  String _statusMessage = 'Awaiting Excel File (.xlsx)';
  int _importedCount = 0;

  Future<void> _pickAndProcessExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Ensures we can read the bytes directly
      );

      if (result != null) {
        setState(() {
          _isProcessing = true;
          _statusMessage = 'Parsing Excel data...';
          _importedCount = 0;
        });

        // Handle file bytes securely across different Android versions
        var bytes = result.files.single.bytes;
        if (bytes == null && result.files.single.path != null) {
          bytes = File(result.files.single.path!).readAsBytesSync();
        }

        if (bytes == null) {
          throw Exception("Could not read file data.");
        }

        var excel = Excel.decodeBytes(bytes);
        int count = 0;

        // Process the first sheet found in the document
        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          
          // Start at index 1 to skip the Header row (assumes Row 0 is headers)
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            
            // Ensure the row isn't completely empty before parsing
            if (row.isNotEmpty && row[0]?.value != null) {
              String studentId = row[0]?.value.toString() ?? '';
              String firstName = row.length > 1 ? row[1]?.value.toString() ?? 'Unknown' : 'Unknown';
              String lastName = row.length > 2 ? row[2]?.value.toString() ?? '' : '';
              String grade = row.length > 3 ? row[3]?.value.toString() ?? 'Unassigned' : 'Unassigned';

              if (studentId.isNotEmpty) {
                final newStudent = Student(
                  studentId: studentId.trim(),
                  firstName: firstName.trim(),
                  lastName: lastName.trim(),
                  grade: grade.trim(),
                  fixedQrData: 'STU-${studentId.trim()}',
                );

                await _dbHelper.addStudent(newStudent);
                count++;
              }
            }
          }
          break; // Only process the first sheet to prevent duplicate cross-sheet imports
        }

        setState(() {
          _importedCount = count;
          _statusMessage = 'Successfully imported $count students into the Master Directory.';
          _isProcessing = false;
        });

      } else {
        setState(() {
          _statusMessage = 'Import cancelled by user.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error processing file: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkCharcoal,
      appBar: AppBar(
        backgroundColor: AppTheme.darkCharcoal,
        title: const Text('Excel Importer', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mintGlow),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Batch Upload Students', style: TextStyle(color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Upload an Excel (.xlsx) file to instantly populate the SQLite database. Ensure your columns are ordered exactly as follows:\n\n1. Student ID\n2. First Name\n3. Last Name\n4. Grade Level',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      _isProcessing ? Icons.sync : (_importedCount > 0 ? Icons.check_circle : Icons.upload_file),
                      color: _isProcessing ? Colors.blueAccent : (_importedCount > 0 ? Colors.greenAccent : AppTheme.mintGlow),
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _importedCount > 0 ? Colors.greenAccent : AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                    if (_isProcessing)
                      const CircularProgressIndicator(color: AppTheme.mintGlow)
                    else
                      ElevatedButton.icon(
                        onPressed: _pickAndProcessExcel,
                        icon: const Icon(Icons.folder_open, color: AppTheme.darkCharcoal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mintGlow,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        label: const Text('SELECT EXCEL FILE', style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}