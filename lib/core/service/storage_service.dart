// lib/services/storage_service.dart
import 'dart:async';
import 'dart:io';
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

  // ✅ FIXED: Add retry logic and timeout
  static Future<String?> uploadFile(String filePath) async {
    const int maxRetries = 3;
    const Duration timeout = Duration(seconds: 30);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (!_initialized) initialize();

        final file = File(filePath);
        if (!file.existsSync()) {
          print('❌ File not found: $filePath');
          return null;
        }

        print('📤 Upload attempt $attempt/$maxRetries');
        print(
          '   File size: ${(file.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
        );

        // Add timeout to prevent hanging
        final response = await _cloudinary
            .uploadFile(
              CloudinaryFile.fromFile(
                filePath,
                resourceType: CloudinaryResourceType.Image,
              ),
            )
            .timeout(
              timeout,
              onTimeout: () {
                throw TimeoutException(
                  'Upload timed out after ${timeout.inSeconds}s',
                );
              },
            );

        print('✅ Upload successful on attempt $attempt');
        print('🔗 URL: ${response.secureUrl}');
        return response.secureUrl;
      } on TimeoutException catch (e) {
        print('⏱️ Attempt $attempt timeout: $e');
        if (attempt < maxRetries) {
          print('🔄 Retrying in ${2 * attempt} seconds...');
          await Future.delayed(
            Duration(seconds: 2 * attempt),
          ); // Exponential backoff
          continue;
        } else {
          print('❌ All $maxRetries retry attempts failed (timeout)');
          return null;
        }
      } on SocketException catch (e) {
        print('🌐 Attempt $attempt network error: ${e.message}');
        if (attempt < maxRetries) {
          print('🔄 Retrying in ${2 * attempt} seconds...');
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        } else {
          print('❌ All $maxRetries retry attempts failed (network error)');
          return null;
        }
      } on CloudinaryException catch (e) {
        print('☁️ Attempt $attempt Cloudinary error: ${e.message}');
        if (attempt < maxRetries) {
          print('🔄 Retrying in ${2 * attempt} seconds...');
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        } else {
          print('❌ All $maxRetries retry attempts failed (Cloudinary error)');
          return null;
        }
      } catch (e) {
        print('❌ Attempt $attempt unexpected error: $e');
        if (attempt < maxRetries) {
          print('🔄 Retrying in ${2 * attempt} seconds...');
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        } else {
          print('❌ All $maxRetries retry attempts failed');
          return null;
        }
      }
    }

    return null;
  }
}
