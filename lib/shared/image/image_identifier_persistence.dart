// lib/shared/image/image_identifier_persistence.dart
import 'dart:io';

import '../../core/image_identifier.dart';
import '../../services/contracts/image_data_service_interface.dart';
import '../../services/utils/image_data_service_extensions.dart';

/// persist temp files to storage via [store]. Optionally delete temp sources
/// on success. Return a list of GUIDs for all images, preserving order in
/// [ids]
Future<List<String>> persistTempImages(
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
