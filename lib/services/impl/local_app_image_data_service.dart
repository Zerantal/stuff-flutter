import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart'; // To get app's documents directory
import 'package:uuid/uuid.dart'; // For generating GUIDs
import '../image_data_service_interface.dart'; // Your updated interface

final Logger _imageLogger = Logger('LocalAppImageDataService');
const String _userImageSubdirectory = 'user_images'; // Define a subdirectory

class LocalAppImageDataService implements IImageDataService {
  // Default placeholder widget to use if a GUID image load fails
  final Widget defaultUserImageErrorPlaceholder;
  final double defaultImageSize;
  final Uuid _uuid;

  // Private constructor for async initialization
  LocalAppImageDataService._privateConstructor({
    required this.defaultUserImageErrorPlaceholder,
    required this.defaultImageSize,
  }) : _uuid = const Uuid();

  // Static async factory method for initialization
  static Future<LocalAppImageDataService> create({
    Widget defaultErrorPlaceholder = const Icon(
      Icons.broken_image_outlined,
      size: 80.0,
      color: Colors.grey,
    ),
    double defaultImgSize = 80.0,
  }) async {
    // Ensure the subdirectory for images exists
    await _ensureImageDirectoryExists();
    return LocalAppImageDataService._privateConstructor(
      defaultUserImageErrorPlaceholder: defaultErrorPlaceholder,
      defaultImageSize: defaultImgSize,
    );
  }

  static Future<Directory> _getUserImageDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDocDir.path}/$_userImageSubdirectory');
    return imageDir;
  }

  static Future<void> _ensureImageDirectoryExists() async {
    try {
      final imageDir = await _getUserImageDirectory();
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
        _imageLogger.info('Created user images directory at ${imageDir.path}');
      }
    } catch (e) {
      _imageLogger.severe('Failed to create user images directory: $e');
      // Depending on the app, you might want to rethrow or handle this more gracefully
    }
  }

  // Helper to get the full path for loading
  Future<String> _getFullPathForGuid(String guidWithExtension) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    // Assuming guidWithExtension is something like "guid.jpg" or "guid.png"
    // and this is stored in Location.imageGuids
    return '${appDocDir.path}/$_userImageSubdirectory/$guidWithExtension';
  }

  @override
  Widget getUserImage(
    String imageGuidWithExtension, { // Expecting "guid.jpg", "guid.png", etc.
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final effectiveWidth = width ?? defaultImageSize;
    final effectiveHeight = height ?? defaultImageSize;

    if (imageGuidWithExtension.isEmpty) {
      _imageLogger.warning(
        "getUserImage called with empty imageGuidWithExtension.",
      );
      return defaultUserImageErrorPlaceholder;
    }

    return FutureBuilder<String>(
      future: _getFullPathForGuid(imageGuidWithExtension),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            // Placeholder while path is resolving
            width: effectiveWidth,
            height: effectiveHeight,
            child: Center(
              child: SizedBox(
                width: effectiveWidth / 2,
                height: effectiveHeight / 2,
                child: const CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          _imageLogger.severe(
            "Error resolving path for GUID '$imageGuidWithExtension': ${snapshot.error}",
          );
          return defaultUserImageErrorPlaceholder;
        }

        final filePath = snapshot.data!;
        final file = File(filePath);

        if (file.existsSync()) {
          // Check existence before attempting to load
          return Image.file(
            file,
            width: effectiveWidth,
            height: effectiveHeight,
            fit: fit ?? BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              _imageLogger.severe(
                "Error loading FILE image for GUID '$imageGuidWithExtension' at '$filePath'. Error: $error",
              );
              return defaultUserImageErrorPlaceholder;
            },
          );
        } else {
          _imageLogger.warning(
            "File image not found for GUID '$imageGuidWithExtension' at '$filePath'.",
          );
          return defaultUserImageErrorPlaceholder;
        }
      },
    );
  }

  @override
  Future<String> saveUserImage(File imageFile) async {
    if (!await imageFile.exists()) {
      _imageLogger.severe(
        "Image file to save does not exist: ${imageFile.path}",
      );
      throw FileSystemException("Source file does not exist", imageFile.path);
    }

    final imageDir = await _getUserImageDirectory();
    if (!await imageDir.exists()) {
      // Should have been created by create(), but good to double check or re-attempt
      await _ensureImageDirectoryExists();
      if (!await imageDir.exists()) {
        _imageLogger.severe(
          "User image directory still does not exist after attempting creation: ${imageDir.path}",
        );
        throw FileSystemException(
          "Destination directory does not exist and could not be created",
          imageDir.path,
        );
      }
    }

    final originalFileExtension = imageFile.path.contains('.')
        ? imageFile.path.substring(imageFile.path.lastIndexOf('.'))
        : '.png'; // Default extension if none found
    final guid = _uuid.v4();
    final newFileName = '$guid$originalFileExtension';
    final newPath = '${imageDir.path}/$newFileName';

    try {
      await imageFile.copy(newPath);
      _imageLogger.info('Saved user image: $newFileName to $newPath');
      return newFileName; // Return "guid.ext"
    } catch (e) {
      _imageLogger.severe('Failed to save user image to $newPath: $e');
      rethrow; // Rethrow the exception to be handled by the caller
    }
  }

  @override
  Future<void> deleteUserImage(String imageGuidWithExtension) async {
    if (imageGuidWithExtension.isEmpty) {
      _imageLogger.warning(
        "deleteUserImage called with empty imageGuidWithExtension.",
      );
      return;
    }
    try {
      final filePath = await _getFullPathForGuid(imageGuidWithExtension);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _imageLogger.info(
          'Deleted user image: $imageGuidWithExtension from $filePath',
        );
      } else {
        _imageLogger.warning(
          'Attempted to delete non-existent user image: $imageGuidWithExtension at $filePath',
        );
      }
    } catch (e) {
      _imageLogger.severe(
        'Failed to delete user image $imageGuidWithExtension: $e',
      );
      rethrow;
    }
  }

  @override
  Future<void> clearAllUserImages() async {
    _imageLogger.info("Attempting to clear all user images...");
    try {
      final imageDir = await _getUserImageDirectory();
      if (await imageDir.exists()) {
        await imageDir.delete(
          recursive: true,
        ); // Delete the directory and its contents
        _imageLogger.info(
          'Successfully deleted user images directory: ${imageDir.path}',
        );
        // Re-create the directory so the app can continue saving new images later
        await _ensureImageDirectoryExists();
      } else {
        _imageLogger.info(
          'User images directory already non-existent, nothing to clear at ${imageDir.path}.',
        );
      }
    } catch (e, s) {
      _imageLogger.severe('Failed to clear all user images: $e', e, s);
    }
  }
}
