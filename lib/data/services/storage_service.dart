import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery and uploads it to Firebase Storage.
  /// Returns the download URL if successful, or null if cancelled or failed.
  Future<String?> pickAndUploadProfilePicture(String userId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null; // User cancelled

      final Reference ref = _storage.ref().child('profile_pictures').child('$userId.jpg');

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(bytes, metadata);
      } else {
        await ref.putFile(File(image.path));
      }

      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error picking or uploading profile picture: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
}
