import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:qra/ustils/supabase_manager.dart';

/// Service for handling profile image upload and management
/// 
/// Features:
/// - Pick images from gallery or camera
/// - Automatic compression and resizing
/// - Store as Base64 in database (no extra storage cost)
/// - Persist across logout/login
class ImageService {
  final supabase = SupabaseManager.client;
  final ImagePicker _picker = ImagePicker();

  /// Pick and upload profile image
  /// 
  /// Returns the image URL (Base64 data URL) or null if cancelled
  Future<String?> pickAndUploadProfileImage(String userId) async {
    try {
      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Read image bytes
      final bytes = await pickedFile.readAsBytes();
      
      // Process and upload
      return await uploadProfileImageFromBytes(userId, bytes);
    } catch (e) {
      print('❌ Error picking image: $e');
      rethrow;
    }
  }

  /// Pick image from camera
  Future<String?> captureAndUploadProfileImage(String userId) async {
    try {
      // Capture image from camera
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Read image bytes
      final bytes = await pickedFile.readAsBytes();
      
      // Process and upload
      return await uploadProfileImageFromBytes(userId, bytes);
    } catch (e) {
      print('❌ Error capturing image: $e');
      rethrow;
    }
  }

  /// Upload profile image from bytes
  Future<String?> uploadProfileImageFromBytes(
    String userId, 
    Uint8List bytes,
  ) async {
    try {
      // Decode image
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to maximum 512x512 while maintaining aspect ratio
      final resized = img.copyResize(
        image,
        width: image.width > 512 ? 512 : null,
        height: image.height > 512 ? 512 : null,
        maintainAspect: true,
      );

      // Convert to JPEG with compression
      final compressed = img.encodeJpg(resized, quality: 85);

      // Check size (warn if > 100KB)
      if (compressed.length > 100 * 1024) {
        print('⚠️ Warning: Compressed image is ${(compressed.length / 1024).toStringAsFixed(2)} KB');
      }

      // Convert to Base64 data URL
      final base64Image = base64Encode(compressed);
      final imageUrl = 'data:image/jpeg;base64,$base64Image';

      // Save to database
      await supabase
          .from('User')
          .update({'ProfileImage': imageUrl})
          .eq('UserId', userId);

      print('✅ Profile image uploaded successfully');
      return imageUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      rethrow;
    }
  }

  /// Get profile image for a user
  Future<String?> getProfileImage(String userId) async {
    try {
      final response = await supabase
          .from('User')
          .select('ProfileImage')
          .eq('UserId', userId)
          .maybeSingle();

      return response?['ProfileImage'] as String?;
    } catch (e) {
      print('❌ Error getting profile image: $e');
      return null;
    }
  }

  /// Get multiple users' profile images
  Future<Map<String, String?>> getBulkProfileImages(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return {};

      final response = await supabase
          .from('User')
          .select('UserId, ProfileImage')
          .inFilter('UserId', userIds);

      final Map<String, String?> images = {};
      for (var row in response as List) {
        images[row['UserId']] = row['ProfileImage'] as String?;
      }

      return images;
    } catch (e) {
      print('❌ Error getting bulk profile images: $e');
      return {};
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage(String userId) async {
    try {
      await supabase
          .from('User')
          .update({'ProfileImage': null})
          .eq('UserId', userId);

      print('✅ Profile image deleted successfully');
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      rethrow;
    }
  }

  /// Check if user has profile image
  Future<bool> hasProfileImage(String userId) async {
    try {
      final image = await getProfileImage(userId);
      return image != null && image.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get image size estimate in bytes
  int getImageSizeEstimate(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return 0;
    
    // Remove data URL prefix if present
    final base64Data = base64Image.contains('base64,') 
        ? base64Image.split('base64,')[1] 
        : base64Image;
    
    // Base64 encoding increases size by ~33%
    // Actual size = (base64 length * 3) / 4
    return (base64Data.length * 3 / 4).round();
  }

  /// Get human-readable image size
  String getReadableImageSize(String? base64Image) {
    final bytes = getImageSizeEstimate(base64Image);
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Validate image before upload
  Future<bool> validateImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      
      if (image == null) return false;
      
      // Check minimum dimensions
      if (image.width < 100 || image.height < 100) {
        throw Exception('Image too small (minimum 100x100)');
      }
      
      // Check maximum dimensions
      if (image.width > 4096 || image.height > 4096) {
        throw Exception('Image too large (maximum 4096x4096)');
      }
      
      return true;
    } catch (e) {
      print('❌ Image validation failed: $e');
      return false;
    }
  }
}

