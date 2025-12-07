import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing profile images with local storage
class ProfileImageService {
  static const String _keyProfileImagePath = 'profile_image_path_';
  static const String _keyProfileImageBase64 = 'profile_image_base64_';

  /// Save profile image path for a user
  static Future<void> saveProfileImagePath(String userId, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyProfileImagePath$userId', imagePath);
  }

  /// Get profile image path for a user
  static Future<String?> getProfileImagePath(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyProfileImagePath$userId');
  }

  /// Save profile image as base64 for a user (for web compatibility)
  static Future<void> saveProfileImageBase64(String userId, String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyProfileImageBase64$userId', base64Image);
  }

  /// Get profile image as base64 for a user
  static Future<String?> getProfileImageBase64(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyProfileImageBase64$userId');
  }

  /// Save image bytes to local storage and return the path
  static Future<String?> saveImageToLocal(String userId, Uint8List imageBytes) async {
    try {
      if (kIsWeb) {
        // For web, save as base64
        final base64Image = base64Encode(imageBytes);
        await saveProfileImageBase64(userId, base64Image);
        return 'base64';
      } else {
        // For mobile, save to app directory
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/profile_$userId.jpg';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);
        await saveProfileImagePath(userId, imagePath);
        return imagePath;
      }
    } catch (e) {
      print('Error saving profile image: $e');
      return null;
    }
  }

  /// Delete profile image for a user
  static Future<void> deleteProfileImage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try to delete the file if it exists
    final imagePath = await getProfileImagePath(userId);
    if (imagePath != null && !kIsWeb) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting profile image file: $e');
      }
    }
    
    // Clear stored paths
    await prefs.remove('$_keyProfileImagePath$userId');
    await prefs.remove('$_keyProfileImageBase64$userId');
  }

  /// Check if user has a profile image
  static Future<bool> hasProfileImage(String userId) async {
    if (kIsWeb) {
      final base64 = await getProfileImageBase64(userId);
      return base64 != null && base64.isNotEmpty;
    } else {
      final path = await getProfileImagePath(userId);
      if (path == null) return false;
      final file = File(path);
      return await file.exists();
    }
  }
}


