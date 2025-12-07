import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../blocs/profile_cubit/profile_cubit.dart';
import '../blocs/profile_cubit/profile_state.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_image_service.dart';
import '../../../auth/screens/welcome_screen.dart';
import '../../../shared/utils/page_transitions.dart';
import '../../../shared/utils/app_colors.dart';
import '../../../shared/widgets/theme_toggle_button.dart';

class ProfilePage extends StatefulWidget {
  final String studentId;
  const ProfilePage({super.key, required this.studentId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _profileImagePath;
  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProfileCubit>().loadStudentProfile(widget.studentId);
    });
  }

  Future<void> _loadProfileImage() async {
    if (kIsWeb) {
      final base64 = await ProfileImageService.getProfileImageBase64(widget.studentId);
      if (mounted) {
        setState(() {
          _profileImageBase64 = base64;
        });
      }
    } else {
      final path = await ProfileImageService.getProfileImagePath(widget.studentId);
      if (mounted) {
        setState(() {
          _profileImagePath = path;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final savedPath = await ProfileImageService.saveImageToLocal(
          widget.studentId,
          bytes,
        );

        if (savedPath != null && mounted) {
          if (kIsWeb) {
            setState(() {
              _profileImageBase64 = base64Encode(bytes);
            });
          } else {
            setState(() {
              _profileImagePath = savedPath;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Profile image updated!'),
                ],
              ),
              backgroundColor: AppColors.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildProfileImage() {
    ImageProvider? imageProvider;

    if (kIsWeb && _profileImageBase64 != null) {
      imageProvider = MemoryImage(base64Decode(_profileImageBase64!));
    } else if (!kIsWeb && _profileImagePath != null) {
      final file = File(_profileImagePath!);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      }
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              backgroundImage: imageProvider ?? const AssetImage("lib/images/image1_.png"),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Prevent back navigation - stay in app
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                "Profile",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            const ThemeToggleButton(),
            IconButton(
              icon: Icon(Icons.logout_rounded, color:Color(0xFFF37721)

              ),
              onPressed: () => _showLogoutDialog(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: BlocBuilder<StudentProfileCubit, StudentProfileState>(
          builder: (context, state) {
            if (state is StudentProfileLoading) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            } else if (state is StudentProfileLoaded) {
              final student = state.student;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Avatar with upload capability
                    _buildProfileImage(),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Student Name
                    Text(
                      student.fullName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Student ID with icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            "ID: ${student.studentCode}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Academic Level with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          student.academicLevel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Info Cards
                    _infoCard(
                      context: context,
                      icon: Icons.email_outlined,
                      title: "Email",
                      value: student.email,
                    ),
                    _infoCard(
                      context: context,
                      icon: Icons.phone_outlined,
                      title: "Phone",
                      value: student.phone ?? "-",
                    ),
                    const SizedBox(height: 16),
                    _infoCard(
                      context: context,
                      icon: Icons.menu_book_rounded,
                      title: "Major",
                      value: student.major,
                    ),
                    _infoCard(
                      context: context,
                      icon: Icons.grade_outlined,
                      title: "GPA",
                      value: student.gpa.toStringAsFixed(2),
                    ),
                    const SizedBox(height: 24),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(Icons.logout_rounded,color: Colors.white),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:Color(0xFFF37721)

                          ,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is StudentProfileError) {
              return Center(child: Text(state.message));
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Widget _infoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    const mainColor = Color(0xFFF37721); // Updated color

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: mainColor, size: 28),
              const SizedBox(width: 12),
              const Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: mainColor),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService.clearLoginSession();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(page: const WelcomeScreen()),
                        (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }


}
