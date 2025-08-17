// lib/services/contracts/image_data_service_interface.dart
import 'dart:io';

import '../../shared/image/image_ref.dart';

abstract class IImageDataService {
  /// Idempotent initialization (e.g., create directories, open caches).
  Future<void> init();

  /// Observability; not required to use.
  bool get isInitialized;

  /// Resolve a GUID to an image reference.
  /// If [verifyExists] is false, implementations may skip I/O and return a best-effort ref.
  Future<ImageRef?> getImage(String imageGuid, {bool verifyExists = true});

  /// Persist a file and return a GUID (usually filename with extension).
  /// Throws on failure.
  Future<String> saveImage(File imageFile, {bool deleteSource = false});

  Future<void> deleteImage(String imageGuid);

  Future<void> deleteAllImages();

  // ---------------------------------------------------------------------------
  // Synchronous, zero-I/O references
  // ---------------------------------------------------------------------------
  /// Build a best-effort [ImageRef] synchronously from a GUID **without** any I/O.
  ///
  /// Implementations should deterministically map a GUID to a path/URL and
  /// return an [ImageRef] (e.g., `ImageRef.file('<store>/<guid>')`).
  /// No existence check should be performed here.
  ///
  /// Use this for list/grid previews and fast UI assembly; rely on the widget’s
  /// ImageProvider to load lazily and surface errors.
  ImageRef refForGuid(String imageGuid);
}
