import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Compress image to reduce file size while maintaining quality
  /// 
  /// Parameters:
  /// - imageBytes: Original image bytes
  /// - maxWidth: Maximum width (default 1920px)
  /// - maxHeight: Maximum height (default 1080px)
  /// - quality: JPEG quality 0-100 (default 85)
  /// 
  /// Returns: Compressed image bytes
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    try {
      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      // Calculate new dimensions while maintaining aspect ratio
      int width = image.width;
      int height = image.height;

      if (width > maxWidth || height > maxHeight) {
        double ratio = width / height;
        
        if (width > height) {
          width = maxWidth;
          height = (width / ratio).round();
        } else {
          height = maxHeight;
          width = (height * ratio).round();
        }

        // Resize image
        image = img.copyResize(
          image,
          width: width,
          height: height,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode to JPEG with quality setting
      final compressedBytes = img.encodeJpg(image, quality: quality);
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      // If compression fails, return original
      return imageBytes;
    }
  }

  /// Get compressed image size info
  static String getImageSizeInfo(Uint8List imageBytes) {
    final sizeInKb = (imageBytes.length / 1024).toStringAsFixed(2);
    final sizeInMb = (imageBytes.length / (1024 * 1024)).toStringAsFixed(2);
    
    if (imageBytes.length < 1024 * 1024) {
      return '$sizeInKb KB';
    } else {
      return '$sizeInMb MB';
    }
  }
}
