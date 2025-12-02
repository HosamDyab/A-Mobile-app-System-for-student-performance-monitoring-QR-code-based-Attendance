// import 'package:flutter/material.dart';
// import 'package:qra/QRCode/presentaion/pages/view_attendance.dart';
// import '../../../ustils/generation.dart';
// import '../../../ustils/scannig.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   final TextEditingController _instanceIdController = TextEditingController();
//   final String studentId = "100002";
//
//   int _selectedIndex = 0;
//
//   @override
//   void dispose() {
//     _instanceIdController.dispose();
//     super.dispose();
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//
//
//     switch (index) {
//       case 1:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ScanQRScreen(studentId: studentId),
//           ),
//         );
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const AttendanceHistoryScreen(),
//           ),
//         );
//         break;
//       case 0:
//       default:
//         break;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const primaryColor = Color(0xFFD97A27);
//
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           'Performance Monitoring',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: primaryColor,
//         elevation: 2,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 10),
//             Text(
//               "Welcome!",
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[800],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               "Manage attendance smoothly using the functions below.",
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 30),
//             TextField(
//               controller: _instanceIdController,
//               decoration: InputDecoration(
//                 filled: true,
//                 fillColor: Colors.white,
//                 labelText: 'Lecture Instance ID',
//                 labelStyle: const TextStyle(color: primaryColor),
//                 prefixIcon: const Icon(Icons.book, color: primaryColor),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: const BorderSide(color: primaryColor, width: 2),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: const BorderSide(color: primaryColor, width: 1.5),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 35),
//             _buildActionCard(
//               icon: Icons.qr_code,
//               title: "Generate QR (Teacher)",
//               subtitle: "Create a lecture QR code for attendance",
//               color: primaryColor,
//               onTap: () {
//                 final instanceId = _instanceIdController.text.trim();
//                 if (instanceId.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Please enter a Lecture Instance ID'),
//                       backgroundColor: Colors.redAccent,
//                     ),
//                   );
//                   return;
//                 }
//
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) =>
//                         GenerateQRCodeScreen(instanceId: instanceId),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 20),
//             // _buildActionCard(
//             //   icon: Icons.camera_alt,
//             //   title: "Scan QR (Student)",
//             //   subtitle: "Scan QR to register attendance",
//             //   color: Colors.green,
//             //   onTap: () {
//             //     Navigator.push(
//             //       context,
//             //       MaterialPageRoute(
//             //         builder: (_) => ScanQRScreen(studentId: studentId),
//             //       ),
//             //     );
//             //   },
//             // ),
//             // const SizedBox(height: 20),
//             // _buildActionCard(
//             //   icon: Icons.list_alt,
//             //   title: "Attendance Records",
//             //   subtitle: "View your attendance history",
//             //   color: Colors.blueAccent,
//             //   onTap: () {
//             //     Navigator.push(
//             //       context,
//             //       MaterialPageRoute(
//             //         builder: (_) => const AttendanceHistoryScreen(),
//             //       ),
//             //     );
//             //   },
//             // ),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         backgroundColor: primaryColor,
//         selectedItemColor: Colors.white,
//         unselectedItemColor: Colors.white70,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.qr_code_scanner),
//             label: 'Scan QR',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.list_alt),
//             label: 'Records',
//           ),
//         ],
//       ),
//
//     );
//   }
//
//   Widget _buildActionCard({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 220),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.25),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 28,
//               backgroundColor: color.withOpacity(0.15),
//               child: Icon(icon, size: 30, color: color),
//             ),
//             const SizedBox(width: 18),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       )),
//                   const SizedBox(height: 4),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
//           ],
//         ),
//       ),
//     );
//   }
// }
