// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import '../../QRCode/presentaion/blocs/attendace_bloc/attendance_cubit.dart';
//
// class ScanQRScreen extends StatefulWidget {
//   final String studentId;
//   const ScanQRScreen({super.key, required this.studentId});
//
//   @override
//   State<ScanQRScreen> createState() => _ScanQRScreenState();
// }
//
// class _ScanQRScreenState extends State<ScanQRScreen>
//     with SingleTickerProviderStateMixin {
//   bool _scanned = false;
//   late AnimationController _animationController;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController =
//     AnimationController(vsync: this, duration: const Duration(seconds: 2))
//       ..repeat(reverse: true);
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onDetect(BarcodeCapture capture) async {
//     if (_scanned) return;
//     setState(() => _scanned = true);
//
//     final code = capture.barcodes.first.rawValue;
//     if (code == null || code.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Invalid QR code.')),
//       );
//       setState(() => _scanned = false);
//       return;
//     }
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(child: CircularProgressIndicator(
//         color:  Color(0xFFD97A27),
//       )),
//     );
//
//     try {
//       final cubit = context.read<AttendanceCubit>();
//       await cubit.markAttendance(widget.studentId, code);
//
//       if (mounted) Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Attendance marked for session: $code')),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       if (mounted) Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to mark attendance: $e')),
//       );
//       setState(() => _scanned = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final orangeColor = const Color(0xFFD97A27);
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Attendance',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const SizedBox(height: 20),
//             const Text(
//               'Scan QR Code',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Point your camera at the QR code provided by your teacher to mark your attendance.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.black54,
//               ),
//             ),
//             const SizedBox(height: 30),
//
//
//             Expanded(
//               child: Center(
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     Container(
//                       width: 300,
//                       height: 300,
//                       decoration: BoxDecoration(
//                         color: Colors.black,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.3),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       clipBehavior: Clip.antiAlias,
//                       child: MobileScanner(
//                         onDetect: _onDetect,
//                       ),
//                     ),
//
//                     AnimatedBuilder(
//                       animation: _animationController,
//                       builder: (context, child) {
//                         return Positioned(
//                           top: 40 +
//                               (220 *
//                                   _animationController.value),
//                           child: Container(
//                             width: 260,
//                             height: 2,
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   orangeColor.withOpacity(0),
//                                   orangeColor,
//                                   orangeColor.withOpacity(0),
//                                 ],
//                                 begin: Alignment.centerLeft,
//                                 end: Alignment.centerRight,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: orangeColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 4,
//                 ),
//                 icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
//                 label: const Text(
//                   'Scan QR Code',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 16,
//                   ),
//                 ),
//                 onPressed: () {
//
//                   setState(() => _scanned = false);
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
