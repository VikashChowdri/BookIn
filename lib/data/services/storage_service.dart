import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

/// A service that handles image picking and converts pictures to compressed
/// Base64 data URIs stored directly in Firestore, completely eliminating
/// the need for Firebase Object Storage buckets.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

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

  /// Picks and compresses a profile picture into a Base64 data URI (1:1 square).
  /// Stored directly in Firestore, bypassing Firebase Object Storage.
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
        maxWidth: 250,
        maxHeight: 250,
        imageQuality: 70,
      );

      if (image == null) return null;

      // Crop image to square (with fallback if crop fails or is unsupported)
      Uint8List bytes;
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
          bytes = await croppedFile.readAsBytes();
        } else {
          bytes = await image.readAsBytes();
        }
      } catch (cropErr) {
        debugPrint('Image cropping skipped/unsupported: $cropErr');
        bytes = await image.readAsBytes();
      }

      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      return base64String;
    } catch (e) {
      debugPrint('Error picking profile picture: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  /// Picks and compresses a book cover image into a Base64 data URI (3:4 aspect ratio).
  /// Stored directly in Firestore, bypassing Firebase Object Storage.
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
        maxWidth: 400,
        maxHeight: 550,
        imageQuality: 65,
      );

      if (image == null) return null;

      // Crop image with 3:4 book aspect ratio (with fallback)
      Uint8List bytes;
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
          bytes = await croppedFile.readAsBytes();
        } else {
          bytes = await image.readAsBytes();
        }
      } catch (cropErr) {
        debugPrint('Book image cropping skipped/unsupported: $cropErr');
        bytes = await image.readAsBytes();
      }

      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      return base64String;
    } catch (e) {
      debugPrint('Error picking book cover: $e');
      throw Exception('Failed to process book cover: $e');
    }
  }

  /// Picks and compresses a chat image into a Base64 data URI.
  /// Stored directly in Firestore message documents, bypassing Firebase Object Storage.
  Future<String?> pickAndUploadChatImage(
    BuildContext context, {
    ImageSource? source,
  }) async {
    try {
      final imageSource = source ?? await showImageSourceSheet(
        context,
        title: 'Send Image',
      );

      if (imageSource == null) return null;

      final XFile? image = await _picker.pickImage(
        source: imageSource,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 60,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      return base64String;
    } catch (e) {
      debugPrint('Error picking chat image: $e');
      throw Exception('Failed to process chat image: $e');
    }
  }
}
