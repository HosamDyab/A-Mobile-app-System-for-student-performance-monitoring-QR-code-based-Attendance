import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQrScreen extends StatelessWidget {
  final VoidCallback onGenerate;

  const GenerateQrScreen({super.key, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2E645C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: "Sample",
            size: 200,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Students can scan this QR code to mark their attendance for the current class.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh QR Code"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
