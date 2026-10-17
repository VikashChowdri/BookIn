import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Helper to decode and provide images whether they are remote HTTP URLs
/// or local Base64 data URIs stored directly in Firestore.
class AppImageHelper {
  AppImageHelper._();

  /// Returns true if the string is a Base64 data URI or raw base64.
  static bool isBase64(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('data:image') || url.startsWith('base64:');
  }

  /// Decodes a Base64 string or data URI into raw image bytes.
  static Uint8List? decodeBase64(String url) {
    try {
      final clean = url.contains(',')
          ? url.split(',').last.trim()
          : url.replaceFirst('base64:', '').trim();
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  /// Returns an [ImageProvider] that handles both Base64 and network URLs.
  static ImageProvider? getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (isBase64(url)) {
      final bytes = decodeBase64(url);
      if (bytes != null) return MemoryImage(bytes);
      return null;
    }
    return CachedNetworkImageProvider(url);
  }

  /// Whether a user avatar URL is a valid custom photo (not empty and not default unsplash).
  static bool hasCustomAvatar(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.contains('unsplash')) return false;
    return true;
  }
}

/// A unified image widget that renders both Base64 images from Firestore
/// and remote URLs via [CachedNetworkImage].
class AppImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final dynamic errorWidget;
  final dynamic placeholder;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.placeholder,
  });

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder is Widget) return placeholder as Widget;
    if (placeholder is Widget Function(BuildContext, String)) {
      return (placeholder as Widget Function(BuildContext, String))(context, imageUrl);
    }
    return const SizedBox.shrink();
  }

  Widget _buildError(BuildContext context, dynamic error) {
    if (errorWidget is Widget) return errorWidget as Widget;
    if (errorWidget is Widget Function(BuildContext, String, dynamic)) {
      return (errorWidget as Widget Function(BuildContext, String, dynamic))(context, imageUrl, error);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (AppImageHelper.isBase64(imageUrl)) {
      final bytes = AppImageHelper.decodeBase64(imageUrl);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildError(ctx, err),
        );
      }
      return _buildError(context, 'Invalid base64 data');
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder != null ? (ctx, url) => _buildPlaceholder(ctx) : null,
      errorWidget: errorWidget != null ? (ctx, url, err) => _buildError(ctx, err) : null,
    );
  }
}
