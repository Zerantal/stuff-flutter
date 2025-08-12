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
  /// Throws on failure.
  Future<String> saveImage(File imageFile, {bool deleteSource = false});

  /// Convenience batch: persists all files in parallel. Throws if any save fails.
  Future<List<String>> saveImages(Iterable<File> files, {bool deleteSource = false}) async {
    return Future.wait(files.map((f) => saveImage(f, deleteSource: deleteSource)));
  }

  Future<void> deleteImage(String imageGuid);

  /// Best-effort batch delete (errors are logged but don’t fail the whole op).
  Future<void> deleteImages(Iterable<String> guids) async {
    await Future.wait(guids.map((g) async {
      try {
        await deleteImage(g);
      } catch (_) {
        // swallow per-file failures; caller already succeeded saving the model
      }
    }));
  }

  Future<void> deleteAllImages();
}
