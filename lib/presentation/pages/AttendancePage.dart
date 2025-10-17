import 'dart:async';
import 'package:flutter/material.dart';

 import '../../utils/qr_utils.dart';
import 'generate_qr_code_page.dart';
import 'live_attendance_screen.dart';


class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String? qrData;
  Timer? _timer;
  int remainingSeconds = 0;
  final List<String> liveAttendance = [];

  void generateQr() {
    setState(() {
      qrData = QrUtils.generateUniqueCode();
      liveAttendance.clear();
      startTimer();
    });
  }

  void startTimer() {
    _timer?.cancel();
    remainingSeconds = 300;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => remainingSeconds--);
      if (remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          qrData = null;
          liveAttendance.clear();
        });
      }
    });
  }

  void endSession() {
    _timer?.cancel();
    setState(() {
      qrData = null;
      remainingSeconds = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR Code'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Grade Entry'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      appBar: AppBar(
        title: const Text("Attendance"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: qrData == null
            ? GenerateQrScreen(onGenerate: generateQr)
            : LiveAttendanceScreen(
          qrData: qrData!,
          remainingSeconds: remainingSeconds,
          onRefresh: generateQr,
          onEndSession: endSession,
          liveAttendance: liveAttendance,
        ),
      ),
    );
  }
}
