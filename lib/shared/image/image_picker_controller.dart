// lib/shared/image/image_picker_controller.dart

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../../services/image_picker_service_interface.dart';
import '../../services/image_data_service_interface.dart';
import '../../services/temporary_file_service_interface.dart';
import 'pick_result.dart';

final Logger _log = Logger('ImagePickerController');

/// Orchestrates image picking and staging with a temp session.
/// - Caller provides a live [TempSession] (controller does NOT dispose it).
/// - Always stages picked files into that session.
/// - If [eagerPersist] is true, immediately persists via [store] and returns a GUID.
/// - Otherwise returns [PickedTemp] and lets the caller persist later via [persistTemp].
///
/// Contract:
///   pickFromGallery / pickFromCamera -> PickResult
///     - PickCancelled
///     - PickFailed(error, stackTrace)
///     - PickedTemp(file)      // file under session dir
///     - SavedGuid(guid)       // if eagerPersist == true & store != null
class ImagePickerController {
  ImagePickerController({
    required IImagePickerService picker,
    required IImageDataService store,
    required this.session,
    this.eagerPersist = false,
  }) : _picker = picker,
       _store = store;

  final IImagePickerService _picker;
  final IImageDataService _store;

  /// When true and a store is available, picked images are persisted
  /// immediately and a [SavedGuid] is returned instead of [PickedTemp].
  final bool eagerPersist;

  final TempSession session;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<PickResult> pickFromGallery() => _pick(_picker.pickImageFromGallery);
  Future<PickResult> pickFromCamera() => _pick(_picker.pickImageFromCamera);

  /// Persist a previously staged temp file to the store.
  /// Returns SavedGuid on success; PickFailed on error.
  Future<PickResult> persistTemp(File staged) async {
    final store = _store;
    try {
      final guid = await store.saveImage(staged, deleteSource: true);
      return SavedGuid(guid);
    } catch (e, s) {
      _log.severe('persistTemp failed', e, s);
      return PickFailed(e, s);
    }
  }

  bool _disposed = false;

  void dispose() {
    _disposed = true; // does NOT dispose the session
  }

  // --- Internals -------------------------------------------------------------

  Future<PickResult> _pick(Future<File?> Function() doPick) async {
    _ensureNotDisposed();
    try {
      final src = await doPick();
      if (src == null) return const PickCancelled();

      // Always stage first to avoid touching user/original locations (esp. Windows).
      final staged = await session.importFile(
        src,
        preferredName: p.basename(src.path),
        deleteSource: false,
      );

      if (eagerPersist) {
        try {
          final guid = await _store.saveImage(staged, deleteSource: true);
          return SavedGuid(guid);
        } catch (e, s) {
          _log.severe('Immediate persist failed; returning staged temp', e, s);
          return PickedTemp(staged);
        }
      }

      return PickedTemp(staged);
    } catch (e, s) {
      _log.severe('pick failed', e, s);
      return PickFailed(e, s);
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('ImagePickerController is disposed');
    }
  }
}
