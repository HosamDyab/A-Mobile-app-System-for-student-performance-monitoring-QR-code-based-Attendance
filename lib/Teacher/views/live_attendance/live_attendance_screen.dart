import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/viewmodels/live_attendance/live_attendance_cubit.dart';
import 'package:qra/Teacher/viewmodels/live_attendance/live_attendance_state.dart';
import 'package:qra/Teacher/services/pdf_generation_service.dart';
import 'package:qra/Teacher/views/widgets/qr_with_logo.dart';
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
  late int _secondsRemaining;
  late Timer _timer;
  bool _isEndingSession = false;
  bool _isSessionEnded = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationMinutes * 60;
    startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LiveAttendanceCubit>().fetchAttend(widget.sessionId);
      }
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
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
      const SnackBar(content: Text("Session Ended. Attendance recording stopped.")),
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

    try {
      // Prepare attendance list for PDF
      final attendanceList = state.attendanceList.map((a) {
        return {
          'name': a.studentName ?? 'Unknown',
          'code': a.studentCode ?? a.studentId,
          'time': a.scanTime,
          'status': a.status,
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

      if (!mounted) return;

      // Show dialog with options
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Report Generated"),
          content: const Text("Your attendance report has been generated successfully."),
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
              icon: const Icon(Icons.print),
              label: const Text("Print/Preview"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD88A2D),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                PdfGenerationService.sharePdf(
                  pdfData,
                  'attendance_${widget.courseTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text("Share"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.courseTitle),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_isSessionEnded) ...[
              const Text(
                "Students can scan this QR code.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // QR Section with MTI Logo
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: QrCodeWidget(
                    data: widget.sessionId,
                    size: 180,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE67E22)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Color(0xFFE67E22)),
                          const SizedBox(width: 8),
                          Text(
                            formatTime(_secondsRemaining),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE67E22),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _showTimerPicker,
                            child: const Text(
                              "Adjust Time",
                              style: TextStyle(
                                color: Color(0xFFE67E22),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isSessionEnded ? Colors.grey.shade300 : const Color(0xFFFFFACD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isSessionEnded ? "Closed" : "Live",
                    style: TextStyle(
                      color: _isSessionEnded ? Colors.black54 : const Color(0xFFFF6B00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ATTEND LIST (From CUBIT)
            Expanded(
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
                      return const Center(child: Text("No students joined yet."));
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.studentName ?? 'Student ${a.studentCode ?? a.studentId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${a.studentCode ?? a.studentId} • ${a.scanTime.toLocal().toString().split('.')[0]}",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateReport,
                  icon: const Icon(Icons.file_download),
                  label: const Text("Generate Report"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEndingSession ? null : endSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isEndingSession
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("End Session"),
                ),
              ),
          ],
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
