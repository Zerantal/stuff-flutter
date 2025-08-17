// lib/shared/image/image_identifier_to_ref.dart
//
// Tiny mapping helpers: VM returns ImageIdentifier(s), view builds Image widgets.

import 'image_ref.dart';
import '../../core/image_identifier.dart';
import '../../services/contracts/image_data_service_interface.dart';

/// Synchronous, zero-I/O conversion of a single identifier into an ImageRef.
/// - `GuidIdentifier` → uses `imageDataService.refForGuid(guid)` (no I/O)
/// - `TempFileIdentifier` → `ImageRef.file(temp.path)` (no I/O)
ImageRef? toImageRefSync(ImageIdentifier id, IImageDataService imageDataService) {
  if (id is GuidIdentifier) {
    return imageDataService.refForGuid(id.guid);
  }
  if (id is TempFileIdentifier) {
    return ImageRef.file(id.file.path);
  }
  return null;
}

/// Synchronous, zero-I/O conversion of multiple identifiers (order preserved).
List<ImageRef> toImageRefsSync(List<ImageIdentifier> ids, IImageDataService imageDataService) {
  return ids
      .map((e) => toImageRefSync(e, imageDataService))
      .where((e) => e != null)
      .cast<ImageRef>()
      .toList(growable: false);
}

/// Convert a single ImageIdentifier to an ImageRef via the service.
Future<ImageRef?> toImageRef(
  ImageIdentifier id,
  IImageDataService imageDataService, {
  bool verifyExists = false,
}) {
  if (!verifyExists) return Future.value(toImageRefSync(id, imageDataService));

  if (id is GuidIdentifier) return imageDataService.getImage(id.guid, verifyExists: true);

  if (id is TempFileIdentifier) return Future.value(ImageRef.file(id.file.path));

  return Future.value(null);
}

/// Convert a list of identifiers to refs (order preserved).
Future<List<ImageRef>> toImageRefs(
  List<ImageIdentifier> ids,
  IImageDataService imageDataService, {
  bool verifyExists = false,
}) async {
  if (!verifyExists) return toImageRefsSync(ids, imageDataService);

  final refs = await Future.wait(
    ids.map((e) => toImageRef(e, imageDataService, verifyExists: true)),
  );
  return refs.where((ref) => ref != null).cast<ImageRef>().toList(growable: false);
}
