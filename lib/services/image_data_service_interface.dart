// lib/services/image_data_service_interface.dart
import 'dart:io';

import '../core/helpers/image_ref.dart';

abstract class IImageDataService {
  /// Idempotent initialization (e.g., create directories, open caches).
  Future<void> init();

  /// Observability; not required to use.
  bool get isInitialized;

  /// Resolve a GUID to an image reference.
  /// If [verifyExists] is false, implementations may skip I/O and return a best-effort ref.
  Future<ImageRef?> getImage(String imageGuid, {bool verifyExists = true});

  /// Persist a file and return a GUID (usually filename with extension).
  Future<String> saveImage(File imageFile);

  Future<void> deleteImage(String imageGuid);
  Future<void> deleteAllImages();
}
