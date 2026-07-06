import 'dart:io';
import 'package:excel/excel.dart';
import '../models/student.dart';
import '../database/database_helper.dart';

class ImportResult {
  int newStudents = 0;
  int existingStudents = 0;
  int enrolledStudents = 0;
  List<String> skippedRows = [];
}

class ExcelImportHelper {
  final DatabaseHelper dbHelper = DatabaseHelper();
  
  Future<ImportResult> importFromExcel(
    String filePath,
    int courseId, {
    Function(String)? onProgress,
  }) async {
    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    
    ImportResult result = ImportResult();
    
    // Assume first sheet
    var sheet = excel.tables.keys.first;
    var table = excel.tables[sheet];
    
    if (table == null || table.rows.isEmpty) {
      throw Exception('Excel file is empty');
    }
    
    // Find column indices (assuming first row is header)
    var headerRow = table.rows.first;
    Map<String, int> columnIndices = {};
    
    for (int i = 0; i < headerRow.length; i++) {
      var cell = headerRow[i];
      String? value = cell?.value?.toString();
      if (value != null) {
        String lowerValue = value.toLowerCase().trim();
        if (lowerValue.contains('student') && lowerValue.contains('id')) {
          columnIndices['student_id'] = i;
        } else if (lowerValue.contains('first') || lowerValue.contains('first_name')) {
          columnIndices['first_name'] = i;
        } else if (lowerValue.contains('last') || lowerValue.contains('last_name')) {
          columnIndices['last_name'] = i;
        } else if (lowerValue.contains('grade') || lowerValue.contains('class')) {
          columnIndices['grade'] = i;
        } else if (lowerValue.contains('qr') || lowerValue.contains('qr_data')) {
          columnIndices['qr_data'] = i;
        }
      }
    }
    
    // Process data rows (skip header)
    for (int i = 1; i < table.rows.length; i++) {
      var row = table.rows[i];
      
      onProgress?.call('Processing row ${i + 1} of ${table.rows.length}');
      
      // Extract values
      String? studentId = _getCellValue(row, columnIndices['student_id']);
      String? firstName = _getCellValue(row, columnIndices['first_name']);
      String? lastName = _getCellValue(row, columnIndices['last_name']);
      String? grade = _getCellValue(row, columnIndices['grade']);
      String? qrData = _getCellValue(row, columnIndices['qr_data']) ?? studentId;
      
      if (studentId == null || studentId.isEmpty) {
        result.skippedRows.add('Row ${i + 1}: Missing student ID');
        continue;
      }
      
      // Check if student exists
      var existingStudent = await dbHelper.getStudentById(studentId);
      
      if (existingStudent == null) {
        // Add new student without image
        Student student = Student(
          studentId: studentId,
          firstName: firstName ?? '',
          lastName: lastName ?? '',
          grade: grade ?? '',
          imagePath: null, // No image from import
          fixedQrData: qrData ?? studentId,
        );
        
        await dbHelper.addStudent(student);
        result.newStudents++;
      } else {
        // Student exists, skip update
        result.existingStudents++;
      }
      
      // Enroll in course
      await dbHelper.enrollStudent(studentId, courseId);
      result.enrolledStudents++;
    }
    
    return result;
  }
  
  String? _getCellValue(List<Data?>? row, int? index) {
    if (index == null || row == null || index >= row.length) return null;
    var cell = row[index];
    return cell?.value?.toString();
  }
}