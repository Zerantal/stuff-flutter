// ImageEditingMixin<T>
// - Manages a TempSession for images
// - Tracks ImageIdentifier list index-aligned with UI images
// - Provides onImagePicked / onRemoveAt handlers
// - Persists temps -> GUIDs using your existing helpers
//
// Requires you to provide a few tiny closures to read/write your state.
// Works alongside your EditEntityMixin<T> (for hasUnsavedChanges & saving).

import 'package:flutter/foundation.dart';

import '../../../core/image_identifier.dart';
import '../../../shared/image/image_ref.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../shared/image/image_identifier_persistence.dart' as persist;
import '../state/image_set.dart';

typedef UpdateImagesCallback = void Function({required ImageSet images, bool notify});

mixin ImageEditingMixin on ChangeNotifier {
  // Services
  late IImageDataService _imageStore;
  late ITemporaryFileService _tempFiles;

  // Session
  TempSession? _session;
  TempSession? get tempSession => _session;
  bool get hasTempSession => _session != null;

  ImageSet _imageSet = ImageSet.empty();
  ImageSet get images => _imageSet;

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
  void seedExistingImages(ImageSet images, {bool notify = true}) {
    _imageSet = images;

    _updateImages(images: _imageSet, notify: notify);
  }

  // ---- UI handlers ----

  /// Wire to ImageManagerInput.onImagePicked
  void onImagePicked(ImageIdentifier id, ImageRef ref) {
    _imageSet = _imageSet.copyWith(
      ids: List<ImageIdentifier>.from(_imageSet.ids) + [id],
      refs: List<ImageRef>.from(_imageSet.refs) + [ref],
    );

    _updateImages(images: _imageSet, notify: true);
  }

  /// Wire to ImageManagerInput.onRemoveAt
  void onRemoveAt(int index, {bool notify = true}) {
    if (index < 0 || index >= _imageSet.ids.length) return;
    _imageSet = _imageSet.copyWith(
      ids: [..._imageSet.ids]..removeAt(index),
      refs: [..._imageSet.refs]..removeAt(index),
    );

    _updateImages(images: _imageSet, notify: notify);
  }

  // ----- Persistence -----

  /// Convert any TempFileIdentifier -> GUID, preserving order.
  /// Also updates `_imageIds` in-place to GuidIdentifier for temps.
  @protected
  Future<List<String>> persistImageGuids({
    bool deleteTempOnSuccess = true,
    bool notify = false,
  }) async {
    final guids = await persist.persistTempImages(
      _imageSet.ids,
      _imageStore,
      deleteTempOnSuccess: deleteTempOnSuccess,
    );

    _imageSet = ImageSet.fromGuids(_imageStore, guids);

    _updateImages(images: _imageSet, notify: notify);

    return guids;
  }
}
