// lib/core/helpers/image_identifier_persistence.dart
import 'dart:io';
import '../image_identifier.dart';
import '../../services/image_data_service_interface.dart';

/// Converts a mixed list of identifiers to GUIDs, persisting temp files via [store].
/// Preserves original ordering. Optionally deletes temp sources on success.
Future<List<String>> ensureGuids(
    List<ImageIdentifier> ids,
    IImageDataService store, {
      bool deleteTempOnSuccess = false,
    }) async {
  final guids = List<String>.filled(ids.length, '', growable: false);

  // Collect temp files and remember their indexes so we can refill in place.
  final tempFiles = <File>[];
  final tempIndexes = <int>[];

  for (var i = 0; i < ids.length; i++) {
    final id = ids[i];
    if (id is GuidIdentifier) {
      guids[i] = id.guid;
    } else if (id is TempFileIdentifier) {
      tempFiles.add(id.file);
      tempIndexes.add(i);
    }
  }

  if (tempFiles.isNotEmpty) {
    final saved = await store.saveImages(tempFiles, deleteSource: deleteTempOnSuccess);
    for (var j = 0; j < saved.length; j++) {
      guids[tempIndexes[j]] = saved[j];
    }
  }

  return guids;
}
