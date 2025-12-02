import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qra/Teacher/viewmodels/attendance/attendance_bloc.dart';
import 'package:qra/Teacher/viewmodels/attendance/attendance_state.dart';
import '../widgets/custom_app_bar.dart';

class QRCodeGenerationScreen extends StatefulWidget {
  const QRCodeGenerationScreen({super.key});

  @override
  State<QRCodeGenerationScreen> createState() => _QRCodeGenerationScreenState();
}

class _QRCodeGenerationScreenState extends State<QRCodeGenerationScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-generate QR code when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AttendanceBloc>().add(GenerateQRCodeEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Attendance'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Generate QR Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: BlocBuilder<AttendanceBloc, AttendanceState>(
                builder: (context, state) {
                  if (state is AttendanceQRGenerated) {
                    return Center(
                      child: QrImageView(
                        data: "LINST-004",
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    );
                  } else if (state is AttendanceLoading) {
                    return const CircularProgressIndicator();
                  } else if (state is AttendanceError) {
                    return Text(state.message);
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Students can scan this QR code to mark their attendance for the current class.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AttendanceBloc>().add(GenerateQRCodeEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Generate QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }
}
