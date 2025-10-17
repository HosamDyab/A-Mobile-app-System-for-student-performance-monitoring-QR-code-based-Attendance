import 'package:flutter/material.dart';
 import 'package:qr_flutter/qr_flutter.dart';

import '../../utils/qr_timer.dart';

class LiveAttendanceScreen extends StatelessWidget {
  final String qrData;
  final int remainingSeconds;
  final VoidCallback onRefresh;
  final VoidCallback onEndSession;
  final List<String> liveAttendance;

  const LiveAttendanceScreen({
    super.key,
    required this.qrData,
    required this.remainingSeconds,
    required this.onRefresh,
    required this.onEndSession,
    required this.liveAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text("Students can scan this QR code.", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E645C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: qrData,
            size: 180,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Text(
              TimerUtils.formatTime(remainingSeconds),
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 20),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: Colors.orange),
              label: const Text("Refresh", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Live Attendance",
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: liveAttendance.isEmpty ? 3 : liveAttendance.length,
            itemBuilder: (context, index) {
              final defaultNames = [
                "Ahmed Gaber Ahmed  — 9:01 AM",
                "Hosam Khaled — 10:02 AM",
                "Ahmed Awad — 12:052 AM"
              ];
              return ListTile(
                title: Text(liveAttendance.isEmpty
                    ? defaultNames[index]
                    : liveAttendance[index]),
                leading: const Icon(Icons.person_outline),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: onEndSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("End Session", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
