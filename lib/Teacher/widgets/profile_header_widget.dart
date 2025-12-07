import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/utils/app_colors.dart';
import '../../services/profile_image_service.dart';

/// Profile Header Widget - Displays user avatar with upload, name, email, and role.
///
/// Features:
/// - Circular avatar with gradient and shadow (matches Student theme)
/// - Image upload capability
/// - Name in large bold text
/// - Email in secondary text
/// - Role chip/badge with icon
/// - Theme-aware styling with AppColors
class ProfileHeaderWidget extends StatefulWidget {
  final String facultyName;
  final String facultyEmail;
  final String role;
  final String? facultyId;

  const ProfileHeaderWidget({
    super.key,
    required this.facultyName,
    required this.facultyEmail,
    required this.role,
    this.facultyId,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  String? _profileImagePath;
  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    if (widget.facultyId == null) return;

    if (kIsWeb) {
      final base64 =
          await ProfileImageService.getProfileImageBase64(widget.facultyId!);
      if (mounted) {
        setState(() {
          _profileImageBase64 = base64;
        });
      }
    } else {
      final path =
          await ProfileImageService.getProfileImagePath(widget.facultyId!);
      if (mounted) {
        setState(() {
          _profileImagePath = path;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (widget.facultyId == null) return;

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
          widget.facultyId!,
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

  /// Returns a user-friendly display name for the role
  String get _roleDisplayName {
    return widget.role == 'faculty' ? 'Faculty' : 'Teacher Assistant';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Avatar with gradient background and upload capability
        _buildAvatar(isDark),
        const SizedBox(height: 8),
        Text(
          'Tap to change photo',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          widget.facultyName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Email
        Text(
          widget.facultyEmail,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Role Chip
        _buildRoleChip(isDark),
      ],
    );
  }

  Widget _buildAvatar(bool isDark) {
    final initial = widget.facultyName.isNotEmpty
        ? widget.facultyName[0].toUpperCase()
        : '?';

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
      child: Hero(
        tag: 'profile_avatar',
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 58,
                  backgroundColor: Colors.transparent,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
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
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.role == 'faculty'
                  ? Icons.school_rounded
                  : Icons.supervisor_account_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _roleDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
