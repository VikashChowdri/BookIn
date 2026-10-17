import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Shows a modal bottom sheet to let the user choose between Camera and Gallery.
  Future<ImageSource?> showImageSourceSheet(
    BuildContext context, {
    String title = 'Select Image Source',
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Camera option
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Use your device camera to capture'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),

              const SizedBox(height: 8),

              // Gallery option
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.green,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Pick an existing image from your gallery'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Picks and uploads a profile picture with 1:1 cropping.
  /// If [source] is null, opens a sheet to let user choose Camera or Gallery.
  /// Returns the download URL if successful, or null if cancelled.
  Future<String?> pickAndUploadProfilePicture(
    BuildContext context,
    String userId, {
    ImageSource? source,
  }) async {
    try {
      final imageSource = source ?? await showImageSourceSheet(
        context,
        title: 'Upload Profile Picture',
      );

      if (imageSource == null) return null;

      final XFile? image = await _picker.pickImage(
        source: imageSource,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Crop image to square (with fallback if crop fails or is unsupported)
      String uploadPath = image.path;
      try {
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
        if (croppedFile != null) {
          uploadPath = croppedFile.path;
        }
      } catch (cropErr) {
        debugPrint('Image cropping skipped/unsupported: $cropErr');
      }

      final Reference ref = _storage
          .ref()
          .child(AppConstants.userAvatarsFolder)
          .child('$userId.jpg');

      if (kIsWeb) {
        final bytes = await File(uploadPath).readAsBytes();
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(bytes, metadata);
      } else {
        await ref.putFile(File(uploadPath));
      }

      final downloadUrl = await ref.getDownloadURL();
      final urlWithTimestamp = downloadUrl.contains('?')
          ? '$downloadUrl&t=${DateTime.now().millisecondsSinceEpoch}'
          : '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      return urlWithTimestamp;
    } catch (e) {
      debugPrint('Error picking or uploading profile picture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Picks and uploads a book cover image (supports Camera or Gallery).
  /// If [source] is null, opens a sheet to let user choose Camera or Gallery.
  /// Returns the download URL if successful, or null if cancelled.
  Future<String?> pickAndUploadBookImage(
    BuildContext context, {
    String? bookId,
    ImageSource? source,
  }) async {
    try {
      final imageSource = source ?? await showImageSourceSheet(
        context,
        title: 'Upload Book Cover',
      );

      if (imageSource == null) return null;

      final XFile? image = await _picker.pickImage(
        source: imageSource,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Crop image with 3:4 book aspect ratio (with fallback)
      String uploadPath = image.path;
      try {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Book Cover',
              toolbarColor: Colors.deepPurple,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.ratio4x3,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Book Cover',
              aspectRatioLockEnabled: false,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
        if (croppedFile != null) {
          uploadPath = croppedFile.path;
        }
      } catch (cropErr) {
        debugPrint('Book image cropping skipped/unsupported: $cropErr');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${bookId ?? 'book'}_$timestamp.jpg';
      final Reference ref = _storage
          .ref()
          .child(AppConstants.bookImagesFolder)
          .child(fileName);

      if (kIsWeb) {
        final bytes = await File(uploadPath).readAsBytes();
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(bytes, metadata);
      } else {
        await ref.putFile(File(uploadPath));
      }

      final downloadUrl = await ref.getDownloadURL();
      final urlWithTimestamp = downloadUrl.contains('?')
          ? '$downloadUrl&t=$timestamp'
          : '$downloadUrl?t=$timestamp';
      return urlWithTimestamp;
    } catch (e) {
      debugPrint('Error picking or uploading book cover: $e');
      throw Exception('Failed to upload book cover: $e');
    }
  }
}
