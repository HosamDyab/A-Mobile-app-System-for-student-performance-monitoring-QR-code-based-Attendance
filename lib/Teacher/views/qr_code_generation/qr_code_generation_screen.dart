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

class _QRCodeGenerationScreenState extends State<QRCodeGenerationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Auto-generate QR code when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AttendanceBloc>().add(GenerateQRCodeEvent());
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(title: 'Attendance QR Code'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header with icon
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667EEA).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance QR Code',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
                          const SizedBox(height: 4),
                          Text(
                            'Valid for 2 hours',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // QR Code Container
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5A67D8), Color(0xFF667EEA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667EEA).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BlocBuilder<AttendanceBloc, AttendanceState>(
                builder: (context, state) {
                  if (state is AttendanceQRGenerated) {
                            return QrImageView(
                              data: state.sessionId,
                        version: QrVersions.auto,
                              size: size.width * 0.6,
                        backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF667EEA),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                      ),
                    );
                  } else if (state is AttendanceLoading) {
                            return SizedBox(
                              height: size.width * 0.6,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            );
                  } else if (state is AttendanceError) {
                            return SizedBox(
                              height: size.width * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 48, color: Colors.red[300]),
                                    const SizedBox(height: 12),
                                    Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                  } else {
                            return SizedBox(
                              height: size.width * 0.6,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            );
                  }
                },
              ),
            ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Scan to mark attendance',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF667EEA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people_rounded,
                            color: Color(0xFF667EEA),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'For Students',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
            const Text(
                      'Students can scan this QR code to mark their attendance for the current class session. The QR code will expire in 2 hours for security.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Grading Information Card
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE67E22).withOpacity(0.1),
                      Color(0xFFD35400).withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE67E22).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFE67E22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.grade_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Grading Breakdown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGradeItem(Icons.quiz, 'Midterm Exam', '20 points'),
                    const SizedBox(height: 8),
                    _buildGradeItem(
                        Icons.description, 'Final Exam', '60 points'),
                    const SizedBox(height: 8),
                    _buildGradeItem(
                        Icons.event_available, 'Attendance', '10 points',
                        subtitle: 'Year Work'),
                    const SizedBox(height: 8),
                    _buildGradeItem(
                        Icons.assignment, 'Assignments & Quizzes', '10 points',
                        subtitle: 'Year Work'),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFFE67E22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '100 points',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Refresh Button
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
              onPressed: () {
                context.read<AttendanceBloc>().add(GenerateQRCodeEvent());
                    _animationController.reset();
                    _animationController.forward();
              },
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: const Text(
                    'Generate New QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Color(0xFFE67E22).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeItem(IconData icon, String title, String points,
      {String? subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Color(0xFFE67E22), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        Text(
          points,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE67E22),
          ),
        ),
      ],
    );
  }
}
