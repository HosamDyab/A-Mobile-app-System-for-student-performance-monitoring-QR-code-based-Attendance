import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/viewmodels/live_attendance/live_attendance_cubit.dart';
import 'package:qra/Teacher/viewmodels/live_attendance/live_attendance_state.dart';
import 'package:qra/Teacher/services/pdf_generation_service.dart';
import 'package:qra/Teacher/views/widgets/qr_with_logo.dart';
import 'package:qra/shared/utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

class LiveAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String courseTitle;
  final int durationMinutes;

  const LiveAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.courseTitle,
    required this.durationMinutes,
  });

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  int _secondsRemaining = 0;
  late Timer _timer;
  late Timer _refreshTimer;
  bool _isEndingSession = false;
  bool _isSessionEnded = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationMinutes * 60;
    startTimer();
    startAutoRefresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🔄 Initial attendance fetch for: ${widget.sessionId}');
        context.read<LiveAttendanceCubit>().fetchAttend(widget.sessionId);
      }
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    if (_refreshTimer.isActive) {
      _refreshTimer.cancel();
    }
    super.dispose();
  }

  void startAutoRefresh() {
    // Refresh attendance list every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _isSessionEnded) {
        timer.cancel();
        return;
      }

      print('🔄 Auto-refreshing attendance...');
      context.read<LiveAttendanceCubit>().fetchAttend(widget.sessionId);
    });
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          endSession();
        }
      });
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int s = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> endSession() async {
    if (_isEndingSession || _isSessionEnded) return;

    setState(() => _isEndingSession = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isEndingSession = false;
      _isSessionEnded = true;
    });

    if (_timer.isActive) {
      _timer.cancel();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Session Ended. Attendance recording stopped.")),
    );
  }

  Future<void> _generateReport() async {
    final state = context.read<LiveAttendanceCubit>().state;

    if (state is! LiveAttendanceLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance data available')),
      );
      return;
    }

    if (state.attendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No students have scanned yet. Cannot generate empty report.')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Prepare attendance list for PDF with proper null handling
      final attendanceList = state.attendanceList.map((a) {
        // Ensure scanTime is properly handled
        DateTime scanDateTime;
        try {
          scanDateTime = a.scanTime;
        } catch (e) {
          print('⚠️ Error parsing scanTime: $e');
          scanDateTime = DateTime.now();
        }

        final studentName = a.studentName?.trim().isNotEmpty == true
            ? a.studentName!
            : 'Student ${a.studentCode ?? a.studentId}';

        final studentCode = a.studentCode?.trim().isNotEmpty == true
            ? a.studentCode!
            : a.studentId;

        final status = a.status.isNotEmpty ? a.status : 'Present';

        return {
          'name': studentName,
          'code': studentCode,
          'time': scanDateTime,
          'status': status,
        };
      }).toList();

      // Generate PDF
      final pdfData = await PdfGenerationService.generateAttendanceReport(
        courseTitle: widget.courseTitle,
        courseCode: widget.courseTitle.split(' ').first,
        sessionId: widget.sessionId,
        instructorName: 'Faculty Member', // You can pass this as parameter
        date: DateTime.now(),
        totalScans: state.attendanceList.length,
        attendanceList: attendanceList,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;

      // Show dialog with download/print options
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.accentPurple],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text("Report Generated"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your attendance report has been generated successfully.",
              ),
              const SizedBox(height: 16),
              Text(
                "Choose an action:",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                PdfGenerationService.printReport(pdfData);
              },
              icon: const Icon(Icons.print, size: 20),
              label: const Text("Print PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD88A2D),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await PdfGenerationService.shareExcel(
                    courseTitle: widget.courseTitle,
                    courseCode: widget.courseTitle.split(' ').first,
                    sessionId: widget.sessionId,
                    instructorName: 'Faculty Member',
                    date: DateTime.now(),
                    attendanceList: attendanceList,
                  );
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Excel file shared successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing Excel: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.table_chart, size: 20),
              label: const Text("Excel"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.accentPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  PdfGenerationService.sharePdf(
                    pdfData,
                    'attendance_${widget.courseTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: const Text("Share PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      print('❌ Error generating report: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _generateReport,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : Colors.grey[50],
      appBar: CustomAppBar(title: widget.courseTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (!_isSessionEnded) ...[
                  // Header text with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.2),
                              AppColors.accentPurple.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Scan QR Code to Mark Attendance",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // QR Section with Enhanced Modern Gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue,
                          AppColors.accentPurple,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // QR Code with white container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: QrCodeWidget(
                            data: widget.sessionId,
                            size: 200,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // "LIVE" badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timer section with modern design
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryOrange.withOpacity(0.1),
                          AppColors.secondaryOrange.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.secondaryOrange.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.timer_rounded,
                            color: AppColors.secondaryOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time Remaining',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white60 : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatTime(_secondsRemaining),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondaryOrange,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showTimerPicker,
                          icon: Icon(
                            Icons.edit_rounded,
                            color: AppColors.secondaryOrange,
                            size: 18,
                          ),
                          label: Text(
                            "Adjust",
                            style: TextStyle(
                              color: AppColors.secondaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                AppColors.secondaryOrange.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text(
                          "Session Ended",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Title + Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Live Attendance",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isSessionEnded
                            ? Colors.grey.shade300
                            : const Color(0xFFFFFACD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isSessionEnded ? "Closed" : "Live",
                        style: TextStyle(
                          color: _isSessionEnded
                              ? Colors.black54
                              : const Color(0xFFFF6B00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ATTEND LIST (From CUBIT)
                SizedBox(
                  height: 300,
                  child: BlocBuilder<LiveAttendanceCubit, LiveAttendanceState>(
                    builder: (context, state) {
                      if (state is LiveAttendanceLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is LiveAttendanceError) {
                        return Center(child: Text("Error: ${state.message}"));
                      }

                      if (state is LiveAttendanceLoaded) {
                        if (state.attendanceList.isEmpty) {
                          return const Center(
                              child: Text("No students joined yet."));
                        }
                        return ListView.builder(
                          itemCount: state.attendanceList.length,
                          itemBuilder: (context, index) {
                            final a = state.attendanceList[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    child: Icon(Icons.person, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.studentName ??
                                              'Student ${a.studentCode ?? a.studentId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${a.studentCode ?? a.studentId} • ${a.scanTime.toLocal().toString().split('.')[0]}",
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }

                      return const Center(child: Text("Waiting for scans..."));
                    },
                  ),
                ),

                const SizedBox(height: 16),

                if (_isSessionEnded)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.accentPurple],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.file_download_rounded, size: 22),
                      label: const Text(
                        "Generate Report",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue,
                          AppColors.secondaryBlue
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isEndingSession ? null : endSession,
                      icon: _isEndingSession
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.stop_circle_rounded, size: 22),
                      label: Text(
                        _isEndingSession ? "Ending..." : "End Session",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTimerPicker() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Session Time"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Minutes"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text;
              final mins = int.tryParse(value) ?? 0;
              if (mins > 0) {
                setState(() => _secondsRemaining = mins * 60);
              }
              Navigator.pop(context);
            },
            child: const Text("Set"),
          ),
        ],
      ),
    );
  }
}
