import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoPath = r'd:\Semester6\sobm\frontend\assets\images\logo.png';
  final logoFile = File(logoPath);
  if (!logoFile.existsSync()) {
    print('Logo file not found: $logoPath');
    return;
  }

  final bytes = logoFile.readAsBytesSync();
  final originalImage = img.decodeImage(bytes);
  if (originalImage == null) {
    print('Failed to decode logo image');
    return;
  }

  print('Original logo dimensions: ${originalImage.width}x${originalImage.height}');

  // Android launcher icon resolutions (mipmap)
  final androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  final resDir = Directory(r'd:\Semester6\sobm\frontend\android\app\src\main\res');
  for (final entry in androidSizes.entries) {
    final folderName = entry.key;
    final size = entry.value;
    final targetFolder = Directory('${resDir.path}\\$folderName');
    if (!targetFolder.existsSync()) {
      targetFolder.createSync(recursive: true);
    }

    final resized = img.copyResize(
      originalImage,
      width: size,
      height: size,
      interpolation: img.Interpolation.cubic,
    );

    final targetFile = File('${targetFolder.path}\\ic_launcher.png');
    targetFile.writeAsBytesSync(img.encodePng(resized));
    print('Generated Android Icon (${size}x${size}): ${targetFile.path}');
  }

  // Web icons
  final webDir = Directory(r'd:\Semester6\sobm\frontend\web');
  if (webDir.existsSync()) {
    final webIcons = {
      r'favicon.png': 32,
      r'icons\Icon-192.png': 192,
      r'icons\Icon-512.png': 512,
      r'icons\Icon-maskable-192.png': 192,
      r'icons\Icon-maskable-512.png': 512,
    };

    for (final entry in webIcons.entries) {
      final relPath = entry.key;
      final size = entry.value;
      final targetFile = File('${webDir.path}\\$relPath');
      final parentDir = targetFile.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      final resized = img.copyResize(
        originalImage,
        width: size,
        height: size,
        interpolation: img.Interpolation.cubic,
      );

      targetFile.writeAsBytesSync(img.encodePng(resized));
      print('Generated Web Icon (${size}x${size}): ${targetFile.path}');
    }
  }

  print('All app launcher icons updated successfully!');
}
