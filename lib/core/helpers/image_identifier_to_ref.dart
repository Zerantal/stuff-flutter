// lib/core/helpers/image_identifier_to_ref.dart
//
// Tiny mapping helpers: VM returns ImageIdentifier(s), view builds Image widgets.

import 'image_ref.dart';
import '../image_identifier.dart';
import '../../services/image_data_service_interface.dart';

/// Convert a single ImageIdentifier to an ImageRef via the service.
Future<ImageRef?> toImageRef(
  ImageIdentifier id,
  IImageDataService imageDataService, {
  bool verifyExists = true,
}) {
  if (id is GuidIdentifier) {
    return imageDataService.getImage(id.guid, verifyExists: verifyExists);
  } else if (id is TempFileIdentifier) {
    return Future.value(ImageRef.file(id.file.path));
  } else {
    return Future.value(null);
  }
}

/// Convert a list of identifiers to refs (order preserved).
Future<List<ImageRef?>> toImageRefs(
  List<ImageIdentifier> ids,
  IImageDataService imageDataService, {
  bool verifyExists = true,
}) async {
  return Future.wait(
    ids.map((e) => toImageRef(e, imageDataService, verifyExists: verifyExists)),
  );
}
