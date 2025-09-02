// ImageEditingMixin<T>
// - Manages a TempSession for images
// - Tracks ImageIdentifier list index-aligned with UI images
// - Provides onImagePicked / onRemoveAt handlers
// - Persists temps -> GUIDs using your existing helpers
//
// Requires you to provide a few tiny closures to read/write your state.
// Works alongside your EditEntityMixin<T> (for hasUnsavedChanges & saving).

import 'dart:collection';
import 'package:flutter/foundation.dart';

import '../../../core/image_identifier.dart';
import '../../../shared/image/image_ref.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../shared/image/image_identifier_persistence.dart' as persist;

typedef UpdateImagesCallback =
    void Function({
      required List<ImageRef> images,
      required List<ImageIdentifier> imageIds,
      bool notify,
    });

mixin ImageEditingMixin on ChangeNotifier {
  // Services
  late IImageDataService _imageStore;
  late ITemporaryFileService _tempFiles;

  // Session
  TempSession? _session;
  TempSession? get tempSession => _session;
  bool get hasTempSession => _session != null;

  // Internal lists kept index-aligned
  final List<ImageRef> _imageRefs = <ImageRef>[];
  final List<ImageIdentifier> _imageIds = <ImageIdentifier>[];

  UnmodifiableListView<ImageRef> get imageRefs => UnmodifiableListView(_imageRefs);
  UnmodifiableListView<ImageIdentifier> get imageIds => UnmodifiableListView(_imageIds);

  late UpdateImagesCallback _updateImages;

  /// Call once (e.g., in VM ctor)
  @protected
  void configureImageEditing({
    required IImageDataService imageStore,
    required ITemporaryFileService tempFiles,
    required UpdateImagesCallback updateImages,
  }) {
    _imageStore = imageStore;
    _tempFiles = tempFiles;
    _updateImages = updateImages;
  }

  // ---- Lifecycle ----

  /// Start a new image temp session. Provide a useful label for debugging/sweeps.
  @protected
  Future<void> startImageSession(String label) async {
    _session = await _tempFiles.startSession(label: label);
    notifyListeners();
  }

  /// Dispose the session. Use `notify:false` from a synchronous dispose().
  @protected
  Future<void> disposeImageSession({bool deleteContents = true, bool notify = false}) async {
    final s = _session;
    if (s == null) return;
    try {
      await s.dispose(deleteContents: deleteContents);
    } finally {
      _session = null;
      if (notify) notifyListeners();
    }
  }

  /// Seed from existing persisted GUIDs (UI order).
  @protected
  void seedExistingImages(List<String> guids, {bool notify = true}) {
    _imageIds
      ..clear()
      ..addAll(guids.map((g) => PersistedImageIdentifier(g)));
    _imageRefs
      ..clear()
      ..addAll(_imageStore.refsForGuids(guids));

    _updateImages(images: _imageRefs, imageIds: _imageIds, notify: notify);
  }

  // ---- UI handlers ----

  /// Wire to ImageManagerInput.onImagePicked
  void onImagePicked(ImageIdentifier id, ImageRef ref) {
    _imageIds.add(id);
    _imageRefs.add(ref);
    _updateImages(images: List.unmodifiable(_imageRefs), imageIds: List.unmodifiable(_imageIds));
  }

  /// Wire to ImageManagerInput.onRemoveAt
  /// Wire to ImageManagerInput.onRemoveAt
  void onRemoveAt(int index, {bool notify = true}) {
    if (index < 0 || index >= _imageRefs.length) return;
    _imageRefs.removeAt(index);
    if (index < _imageIds.length) _imageIds.removeAt(index);
    _updateImages(images: List.unmodifiable(_imageRefs), imageIds: List.unmodifiable(_imageIds));
  }

  // ----- Persistence -----

  /// Convert any TempFileIdentifier -> GUID, preserving order.
  /// Also updates `_imageIds` in-place to GuidIdentifier for temps.
  @protected
  Future<List<String>> persistImageGuids({bool deleteTempOnSuccess = true}) async {
    final guids = await persist.persistTempImages(
      _imageIds,
      _imageStore,
      deleteTempOnSuccess: deleteTempOnSuccess,
    );
    for (var i = 0; i < _imageIds.length; i++) {
      final id = _imageIds[i];
      if (id is TempImageIdentifier) {
        final g = guids[i];
        if (g.isNotEmpty) _imageIds[i] = PersistedImageIdentifier(g);
      }
    }
    // no notify here; VM will typically call applyImagesToState after save if needed
    return guids;
  }
}
