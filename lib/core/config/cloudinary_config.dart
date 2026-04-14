class CloudinaryConfig {
  // ✅ Replace with YOUR values from Cloudinary Dashboard
  static const String cloudName = 'dljqnuaep';
  static const String uploadPreset =
      'Chat_upload_prset'; 

  // Optional: Base folder for all uploads
  static const String baseFolder = 'chatApp';

  static void printConfig() {
    print('═══════════════════════════════════════════');
    print('☁️ CLOUDINARY CONFIG');
    print('═══════════════════════════════════════════');
    print('Cloud Name: $cloudName');
    print('Upload Preset: $uploadPreset');
    print('Base Folder: $baseFolder');
    print('═══════════════════════════════════════════');
  }
}
