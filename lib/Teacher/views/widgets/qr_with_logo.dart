import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QR Code widget with MTI logo in the center
class QrWithLogo extends StatelessWidget {
  final String data;
  final double size;

  const QrWithLogo({
    super.key,
    required this.data,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size - 32,
        backgroundColor: Colors.white,
        // Add MTI logo in the center
        embeddedImage: const AssetImage('assets/images/mti_logo.png'),
        embeddedImageStyle: const QrEmbeddedImageStyle(
          size: Size(60, 60),
        ),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFFD88A2D), // MTI Orange
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}

/// Fallback QR Code widget without logo (if asset not available)
class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size - 32,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFFD88A2D), // MTI Orange
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}

