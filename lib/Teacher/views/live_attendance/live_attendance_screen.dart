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
  bool _isEndingSession = false;
  bool _isSessionEnded = false;


  @override
  void initState() {
    super.initState();

    print('🔍 ========================================');
    print('🔍 SESSION ID DEBUG');
    print('🔍 ========================================');
    print('📱 Screen initialized with:');
    print('   - Session ID: ${widget.sessionId}');
    print('   - Course Title: ${widget.courseTitle}');
    print('   - Duration: ${widget.durationMinutes} minutes');
    print('🔍 Session ID format check:');
    print('   - Starts with L? ${widget.sessionId.toUpperCase().startsWith("L")}');
    print('   - Starts with S? ${widget.sessionId.toUpperCase().startsWith("S")}');
    print('   - Length: ${widget.sessionId.length}');
    print('🔍 ========================================');

    // Set initial timer
    _secondsRemaining = widget.durationMinutes * 60;

    // Start countdown timer
    startTimer();

    // Start polling for attendance updates every 3 seconds
    context.read<LiveAttendanceCubit>().startPolling(
      widget.sessionId,
      intervalSeconds: 3,
    );
  }
  @override
  void dispose() {
    print('📱 LiveAttendanceScreen disposed - stopping polling');

    // Stop polling when leaving the screen
    context.read<LiveAttendanceCubit>().stopPolling();

    // Cancel timers
    if (_timer.isActive) {
      _timer.cancel();
    }

    super.dispose();
  }

  // Manual refresh method
  void _refreshAttendance() {
    print('🔄 Manual refresh triggered');
    context.read<LiveAttendanceCubit>().fetchAttend(widget.sessionId);
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

    // Stop polling when session ends
    context.read<LiveAttendanceCubit>().stopPolling();

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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final attendanceList = state.attendanceList.map((a) {
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

      final pdfData = await PdfGenerationService.generateAttendanceReport(
        courseTitle: widget.courseTitle,
        courseCode: widget.courseTitle.split(' ').first,
        sessionId: widget.sessionId,
        instructorName: 'Faculty Member',
        date: DateTime.now(),
        totalScans: state.attendanceList.length,
        attendanceList: attendanceList,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;

      _showReportDialog(context, attendanceList, pdfData);
    } catch (e) {
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

  void _showReportDialog(BuildContext context, List<Map<String, dynamic>> attendanceList, dynamic pdfData) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

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
            Flexible(
              child: Text(
                "Report Generated",
                style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
              ),
            ),
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
        actions: isSmallScreen
            ? [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPrintButton(ctx, pdfData),
                const SizedBox(height: 8),
                _buildExcelButton(ctx, attendanceList),
                const SizedBox(height: 8),
                _buildSharePdfButton(ctx, pdfData),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        ]
            : [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          _buildPrintButton(ctx, pdfData),
          _buildExcelButton(ctx, attendanceList),
          _buildSharePdfButton(ctx, pdfData),
        ],
      ),
    );
  }

  Widget _buildPrintButton(BuildContext ctx, dynamic pdfData) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(ctx);
        PdfGenerationService.printReport(pdfData);
      },
      icon: const Icon(Icons.print, size: 20),
      label: const Text("Print PDF"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD88A2D),
      ),
    );
  }

  Widget _buildExcelButton(BuildContext ctx, List<Map<String, dynamic>> attendanceList) {
    return ElevatedButton.icon(
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
    );
  }

  Widget _buildSharePdfButton(BuildContext ctx, dynamic pdfData) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 1024;
    final isLandscape = orientation == Orientation.landscape;

    final qrSize = isDesktop ? 250.0 : (isTablet ? 220.0 : 200.0);
    final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 24.0 : 20.0);
    final attendanceListHeight = isDesktop ? 400.0 : (isTablet ? 350.0 : 300.0);

    return Scaffold(
      backgroundColor: isDark ? null : Colors.grey[50],
      appBar: CustomAppBar(
        title: widget.courseTitle,
        actions: [
          // Add manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshAttendance,
            tooltip: 'Refresh Attendance',
          ),
        ],
      ),
      body: SafeArea(
        child: isLandscape && !isTablet
            ? _buildLandscapeLayout(context, isDark, qrSize, horizontalPadding, attendanceListHeight)
            : _buildPortraitLayout(context, isDark, qrSize, horizontalPadding, attendanceListHeight, isTablet, isDesktop),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, bool isDark, double qrSize, double horizontalPadding, double attendanceListHeight) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              children: [
                if (!_isSessionEnded) ...[
                  _buildQrSection(context, isDark, qrSize),
                  const SizedBox(height: 16),
                  _buildTimerSection(context, isDark),
                ] else
                  _buildSessionEndedBanner(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAttendanceHeader(context),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildAttendanceList(context, double.infinity),
                ),
                const SizedBox(height: 16),
                _buildActionButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, bool isDark, double qrSize, double horizontalPadding, double attendanceListHeight, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isTablet ? 24 : 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
            child: Column(
              children: [
                if (!_isSessionEnded) ...[
                  _buildHeader(context, isDark, isTablet),
                  SizedBox(height: isTablet ? 28 : 24),
                  _buildQrSection(context, isDark, qrSize),
                  SizedBox(height: isTablet ? 28 : 24),
                  _buildTimerSection(context, isDark),
                ] else
                  _buildSessionEndedBanner(),

                const SizedBox(height: 20),
                _buildAttendanceHeader(context),
                const SizedBox(height: 10),
                _buildAttendanceList(context, attendanceListHeight),
                const SizedBox(height: 16),
                _buildActionButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isTablet) {
    return Row(
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
            size: isTablet ? 28 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            "Scan QR Code to Mark Attendance",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrSection(BuildContext context, bool isDark, double qrSize) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(qrSize > 220 ? 28 : 24),
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
              size: qrSize,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }

  Widget _buildTimerSection(BuildContext context, bool isDark) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Container(
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
      child: isSmallScreen
          ? Column(
        children: [
          Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _showTimerPicker,
              icon: Icon(
                Icons.edit_rounded,
                color: AppColors.secondaryOrange,
                size: 18,
              ),
              label: Text(
                "Adjust Time",
                style: TextStyle(
                  color: AppColors.secondaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.secondaryOrange.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      )
          : Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
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
          ),
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
              backgroundColor: AppColors.secondaryOrange.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionEndedBanner() {
    return Container(
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
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Live Attendance",
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isSessionEnded ? Colors.grey.shade300 : const Color(0xFFFFFACD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isSessionEnded) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B00),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                _isSessionEnded ? "Closed" : "Live",
                style: TextStyle(
                  color: _isSessionEnded ? Colors.black54 : const Color(0xFFFF6B00),
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList(BuildContext context, double height) {
    return SizedBox(
      height: height,
      child: BlocBuilder<LiveAttendanceCubit, LiveAttendanceState>(
        builder: (context, state) {
          if (state is LiveAttendanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LiveAttendanceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${state.message}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshAttendance,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is LiveAttendanceLoaded) {
            if (state.attendanceList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No students joined yet.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Waiting for scans...",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.attendanceList.length,
              itemBuilder: (context, index) {
                final a = state.attendanceList[index];
                final size = MediaQuery.of(context).size;
                final isSmallScreen = size.width < 400;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isSmallScreen ? 18 : 22,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: isSmallScreen ? 18 : 22,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.studentName ?? 'Student ${a.studentCode ?? a.studentId}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${a.studentCode ?? a.studentId} • ${_formatTime(a.scanTime)}",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 16),
                const Text("Initializing session..."),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButton(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSessionEnded
              ? [AppColors.primaryBlue, AppColors.accentPurple]
              : [AppColors.primaryBlue, AppColors.secondaryBlue],
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
        onPressed: _isSessionEnded
            ? _generateReport
            : (_isEndingSession ? null : endSession),
        icon: _isEndingSession
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Icon(
          _isSessionEnded
              ? Icons.file_download_rounded
              : Icons.stop_circle_rounded,
          size: 22,
        ),
        label: Text(
          _isEndingSession
              ? "Ending..."
              : (_isSessionEnded ? "Generate Report" : "End Session"),
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showTimerPicker() {
    final controller = TextEditingController();
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                Icons.timer_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Set Session Time",
              style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Minutes",
            border: const OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.timer,
              color: AppColors.primaryBlue,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text;
              final mins = int.tryParse(value) ?? 0;
              if (mins > 0) {
                setState(() {
                  _secondsRemaining = mins * 60;
                  // Restart timer with new duration
                  if (_timer.isActive) {
                    _timer.cancel();
                  }
                  startTimer();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session time set to $mins minutes'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.accentGreen,
                  ),
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text("Set"),
          ),
        ],
      ),
    );
  }
}