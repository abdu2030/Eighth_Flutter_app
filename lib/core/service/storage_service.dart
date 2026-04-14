// lib/services/storage_service.dart
import 'package:chat_app/core/config/cloudinary_config.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class StorageService {
  static late final CloudinaryPublic _cloudinary;
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    // Print config for debugging
    CloudinaryConfig.printConfig();

    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );

    _initialized = true;
    print('✅ Cloudinary initialized');
  }

  // Public method to upload file (used in signup)
  static Future<String?> uploadFile(String filePath) async {
    try {
      if (!_initialized) initialize();

      print('📤 Uploading: $filePath');

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('✅ Upload success: ${response.secureUrl}');
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('❌ Cloudinary error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }
}
