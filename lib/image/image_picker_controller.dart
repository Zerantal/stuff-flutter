import 'dart:io';

import 'package:logging/logging.dart';

import '../services/image_data_service_interface.dart';
import '../services/image_picker_service_interface.dart';
import '../services/temporary_file_service_interface.dart';
import 'pick_result.dart';

/// Optional, pluggable image processor (e.g., downscale, compress).
typedef ImageProcessor = Future<File> Function(File input);

/// Identity processor (no-op).
Future<File> _identityProcessor(File f) async => f;

final Logger _log = Logger('ImagePickerController');


/// A small, test-friendly façade that owns the “pick / process / persist” flow.
/// - No UI or VM state here.
/// - No mixins; everything is explicit and injectable.
/// - All IO is behind interfaces you already have.
class ImagePickerController {
  final IImagePickerService picker;
  final IImageDataService? store;
  final ITemporaryFileService? temp;
  final ImageProcessor process;

  ImagePickerController({
    required this.picker,
    this.store,
    this.temp,
    ImageProcessor? processor,
  }) : process = processor ?? _identityProcessor;

  /// Pick from gallery -> (optionally) process -> return temp file.
  Future<PickResult> pickFromGallery() async {
    return _pick(() => picker.pickImageFromGallery());
  }

  /// Pick from camera -> (optionally) process -> return temp file.
  Future<PickResult> pickFromCamera() async {
    return _pick(() => picker.pickImageFromCamera());
  }

  /// Persist a temp file via the image store; returns SavedGuid on success.
  Future<PickResult> persistTemp(File tempFile) async {
    if (store == null) {
      return PickFailed(
        StateError('No IImageDataService configured; cannot persist'),
      );
    }
    try {
      final guid = await store!.saveImage(tempFile);
      _log.fine('Persisted image; guid=$guid');
      return SavedGuid(guid);
    } catch (e, s) {
      _log.severe('Failed to persist image', e, s);
      return PickFailed(e, s);
    }
  }

  /// Convenience: pick (gallery), then persist if pick succeeded.
  Future<PickResult> pickFromGalleryAndPersist() async {
    final r = await pickFromGallery();
    if (r is PickedTemp) return persistTemp(r.file);
    return r;
  }

  /// Convenience: pick (camera), then persist if pick succeeded.
  Future<PickResult> pickFromCameraAndPersist() async {
    final r = await pickFromCamera();
    if (r is PickedTemp) return persistTemp(r.file);
    return r;
  }

  // ---- internals -----------------------------------------------------------

  Future<PickResult> _pick(Future<dynamic> Function() doPick) async {
    try {
      final picked =
          await doPick(); // dynamic to avoid hard dependency on XFile
      final file = _asFile(picked);
      if (file == null) return const PickCancelled();

      // Optional: copy to your temp location (if you prefer all files under app temp)
      final staged = await _ensureInTemp(file);

      // Optional: run processor (e.g., downscale, compress)
      final processed = await process(staged);

      return PickedTemp(processed);
    } catch (e, s) {
      _log.severe('Pick failed', e, s);
      return PickFailed(e, s);
    }
  }

  File? _asFile(dynamic picked) {
    if (picked == null) return null;
    if (picked is File) return picked;
    // Many pickers return XFile; duck-type the .path to avoid a hard import.
    try {
      final path = (picked as dynamic).path as String?;
      return path != null ? File(path) : null;
    } catch (_) {
      return null;
    }
  }

  Future<File> _ensureInTemp(File f) async {
    if (temp == null) return f;
    try {
      // If your ITemporaryFileService uses a different method name, adapt here.
      final copied = await temp!.copyToTemp(f);
      return copied;
    } catch (e, s) {
      // If copying fails, log and fall back to original path.
      _log.warning('Failed to copy to temp; using original', e, s);
      return f;
    }
  }
}
