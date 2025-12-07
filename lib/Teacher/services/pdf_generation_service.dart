import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class PdfGenerationService {
  /// Generate attendance report PDF with QR code
  static Future<Uint8List> generateAttendanceReport({
    required String courseTitle,
    required String courseCode,
    required String sessionId,
    required String instructorName,
    required DateTime date,
    required int totalScans,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    try {
      print('📄 Generating PDF report...');
      print('   Course: $courseTitle');
      print('   Records: ${attendanceList.length}');

      final pdf = pw.Document();

      // Generate QR code image with error handling
      pw.MemoryImage? qrImage;

      try {
        final qrValidationResult = QrValidator.validate(
          data: sessionId,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        );

        if (qrValidationResult.status == QrValidationStatus.valid) {
          final qrCode = qrValidationResult.qrCode!;
          final painter = QrPainter.withQr(
            qr: qrCode,
            color: const ui.Color(0xFF000000),
            emptyColor: const ui.Color(0xFFFFFFFF),
            gapless: true,
            embeddedImageStyle: null,
            embeddedImage: null,
          );

          final picData = await painter.toImageData(300);
          if (picData != null) {
            qrImage = pw.MemoryImage(picData.buffer.asUint8List());
          }
        }
      } catch (e) {
        print('Error generating QR code for PDF: $e');
        // Continue without QR image if it fails
      }

      // Always add a page (with or without QR code)
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.orange,
                    width: 3,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MTI University',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Attendance Report',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        DateFormat('MMMM dd, yyyy').format(date),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        DateFormat('hh:mm a').format(date),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Course Information
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Course',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            courseTitle,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            courseCode,
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Instructor',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            instructorName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // QR Code Section (only if QR image was successfully generated)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: qrImage != null ? 2 : 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Session Information',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildInfoRow('Session ID:', sessionId),
                      _buildInfoRow('Total Scans:', totalScans.toString()),
                      _buildInfoRow(
                        'Date:',
                        DateFormat('MMM dd, yyyy').format(date),
                      ),
                      _buildInfoRow(
                        'Time:',
                        DateFormat('hh:mm a').format(date),
                      ),
                    ],
                  ),
                ),
                if (qrImage != null) ...[
                  pw.SizedBox(width: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.orange, width: 2),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Image(qrImage, width: 150, height: 150),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Session QR Code',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 30),

            // Attendance Table
            pw.Text(
              'Attendance List',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.orange),
                  children: [
                    _buildTableCell('#', isHeader: true),
                    _buildTableCell('Student Name', isHeader: true),
                    _buildTableCell('Student Code', isHeader: true),
                    _buildTableCell('Scan Time', isHeader: true),
                    _buildTableCell('Status', isHeader: true),
                  ],
                ),
                // Data Rows
                ...attendanceList.asMap().entries.map(
                  (entry) {
                    try {
                      // Safely extract values with fallbacks
                      final name = entry.value['name']?.toString() ?? 'Unknown';
                      final code = entry.value['code']?.toString() ?? 'N/A';

                      // Handle time with extra safety
                      String timeStr = 'N/A';
                      try {
                        final timeValue = entry.value['time'];
                        if (timeValue != null) {
                          if (timeValue is DateTime) {
                            timeStr = DateFormat('hh:mm a').format(timeValue);
                          } else if (timeValue is String) {
                            final parsedTime = DateTime.tryParse(timeValue);
                            if (parsedTime != null) {
                              timeStr =
                                  DateFormat('hh:mm a').format(parsedTime);
                            }
                          }
                        }
                      } catch (e) {
                        print('Error formatting time for row ${entry.key}: $e');
                        timeStr = 'N/A';
                      }

                      final status =
                          entry.value['status']?.toString() ?? 'Present';

                      return pw.TableRow(
                        decoration: entry.key % 2 == 0
                            ? const pw.BoxDecoration(color: PdfColors.grey100)
                            : null,
                        children: [
                          _buildTableCell((entry.key + 1).toString()),
                          _buildTableCell(name),
                          _buildTableCell(code),
                          _buildTableCell(timeStr),
                          _buildTableCell(status, isStatus: true),
                        ],
                      );
                    } catch (e) {
                      print('Error creating table row ${entry.key}: $e');
                      // Return a safe error row
                      return pw.TableRow(
                        children: [
                          _buildTableCell((entry.key + 1).toString()),
                          _buildTableCell('Error'),
                          _buildTableCell('Error'),
                          _buildTableCell('Error'),
                          _buildTableCell('Error', isStatus: true),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            pw.SizedBox(height: 30),
          ],
          footer: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by MTI Attendance System',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      print('✅ PDF generated successfully');
      return pdf.save();
    } catch (e, stackTrace) {
      print('❌ Error generating PDF: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, bool isStatus = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Show print preview dialog
  static Future<void> printReport(Uint8List pdfData) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
    );
  }

  /// Share PDF file
  static Future<void> sharePdf(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(
      bytes: pdfData,
      filename: filename,
    );
  }

  /// Generate CSV/Excel file from attendance data
  static Future<String> generateExcelReport({
    required String courseTitle,
    required String courseCode,
    required String sessionId,
    required String instructorName,
    required DateTime date,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    // Prepare CSV data
    List<List<dynamic>> rows = [];

    // Add header information
    rows.add(['MTI University - Attendance Report']);
    rows.add(['Course', courseTitle]);
    rows.add(['Course Code', courseCode]);
    rows.add(['Instructor', instructorName]);
    rows.add(['Session ID', sessionId]);
    rows.add(['Date', DateFormat('MMMM dd, yyyy').format(date)]);
    rows.add(['Time', DateFormat('hh:mm a').format(date)]);
    rows.add(['Total Students', attendanceList.length.toString()]);
    rows.add([]); // Empty row

    // Add table headers
    rows.add(['#', 'Student Name', 'Student Code', 'Scan Time', 'Status']);

    // Add attendance data
    for (int i = 0; i < attendanceList.length; i++) {
      final record = attendanceList[i];
      rows.add([
        (i + 1).toString(),
        record['name'] ?? 'Unknown',
        record['code'] ?? 'N/A',
        record['time'] != null && record['time'] is DateTime
            ? DateFormat('hh:mm a').format(record['time'])
            : 'N/A',
        record['status'] ?? 'Present',
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save to file
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filename =
          'attendance_${courseCode}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csv);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save Excel file: $e');
    }
  }

  /// Share Excel/CSV file
  static Future<void> shareExcel({
    required String courseTitle,
    required String courseCode,
    required String sessionId,
    required String instructorName,
    required DateTime date,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    try {
      // Generate CSV content
      List<List<dynamic>> rows = [];

      // Add header information
      rows.add(['MTI University - Attendance Report']);
      rows.add(['Course', courseTitle]);
      rows.add(['Course Code', courseCode]);
      rows.add(['Instructor', instructorName]);
      rows.add(['Session ID', sessionId]);
      rows.add(['Date', DateFormat('MMMM dd, yyyy').format(date)]);
      rows.add(['Time', DateFormat('hh:mm a').format(date)]);
      rows.add(['Total Students', attendanceList.length.toString()]);
      rows.add([]); // Empty row

      // Add table headers
      rows.add(['#', 'Student Name', 'Student Code', 'Scan Time', 'Status']);

      // Add attendance data
      for (int i = 0; i < attendanceList.length; i++) {
        final record = attendanceList[i];
        rows.add([
          (i + 1).toString(),
          record['name'] ?? 'Unknown',
          record['code'] ?? 'N/A',
          record['time'] != null && record['time'] is DateTime
              ? DateFormat('hh:mm a').format(record['time'])
              : 'N/A',
          record['status'] ?? 'Present',
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Save temporarily and share
      final directory = await getTemporaryDirectory();
      final filename =
          'attendance_${courseCode}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csv);

      // Share using printing package (it supports sharing files)
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: filename,
      );
    } catch (e) {
      throw Exception('Failed to share Excel file: $e');
    }
  }
}
