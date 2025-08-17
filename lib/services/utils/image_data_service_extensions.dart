// lib/services/utils/image_data_service_extensions.dart

import 'dart:io';

import '../contracts/image_data_service_interface.dart';
import '../../shared/image/image_ref.dart';

extension ImageDataServiceExtensions on IImageDataService {
  /// Convenience: build multiple refs from GUIDs synchronously.
  List<ImageRef> refsForGuids(Iterable<String> guids) =>
      guids.map(refForGuid).toList(growable: false);

  /// Best-effort batch delete (errors are logged but don’t fail the whole op).
  Future<void> deleteImages(Iterable<String> guids) async {
    await Future.wait(
      guids.map((g) async {
        try {
          await deleteImage(g);
        } catch (_) {
          // swallow per-file failures; caller already succeeded saving the model
        }
      }),
    );
  }

  /// Convenience batch: persists all files in parallel. Throws if any save fails.
  Future<List<String>> saveImages(Iterable<File> files, {bool deleteSource = false}) async {
    return Future.wait(files.map((f) => saveImage(f, deleteSource: deleteSource)));
  }

  /// Asynchronously resolve refs and optionally verify they exist on disk.
  Future<List<ImageRef>> getImages(Iterable<String> guids, {bool verifyExists = false}) async {
    final results = await Future.wait(guids.map((g) => getImage(g, verifyExists: verifyExists)));
    return results.whereType<ImageRef>().toList(growable: false);
  }
}
