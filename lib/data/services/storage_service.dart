import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery and uploads it to Firebase Storage.
  /// Returns the download URL if successful, or null if cancelled or failed.
  Future<String?> pickAndUploadProfilePicture(BuildContext context, String userId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null; // User cancelled

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return null;

      final Reference ref = _storage.ref().child('profile_pictures').child('$userId.jpg');

      if (kIsWeb) {
        final bytes = await croppedFile.readAsBytes();
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(bytes, metadata);
      } else {
        await ref.putFile(File(croppedFile.path));
      }

      final downloadUrl = await ref.getDownloadURL();
      final urlWithTimestamp = downloadUrl.contains('?') 
          ? '$downloadUrl&t=${DateTime.now().millisecondsSinceEpoch}'
          : '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      return urlWithTimestamp;
    } catch (e) {
      debugPrint('Error picking or uploading profile picture: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
}
