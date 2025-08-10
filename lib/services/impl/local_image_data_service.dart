// lib/services/impl/local_image_data_service.dart
//
// A file-backed implementation of IImageDataService that saves images
// to an app-scoped directory and resolves GUIDs to ImageRef.file.

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/helpers/image_ref.dart';
import '../image_data_service_interface.dart';

/// Stores images under `<app support>/images` by default.
/// - GUID == filename (including extension), so no extra index/mapping needed.
/// - Derives the file path from the GUID and returns ImageRef.file(path).
class LocalImageDataService implements IImageDataService {
  final String subdirName;
  final Directory? _baseDirOverride; // for testing / customization
  Directory? _imagesDir; // lazily created & cached

  LocalImageDataService({this.subdirName = 'images', Directory? baseDir})
    : _baseDirOverride = baseDir;

  Completer<void>? _initCompleter;

  @override
  bool get isInitialized => _imagesDir != null;

  @override
  Future<void> init() => _initOnce();

  @override
  Future<ImageRef?> getImage(
    String imageGuid, {
    bool verifyExists = true,
  }) async {
    await _initOnce();
    final safe = _sanitizeGuid(imageGuid);
    final path = p.join(_imagesDir!.path, safe);
    if (!verifyExists) return ImageRef.file(path);
    return await File(path).exists() ? ImageRef.file(path) : null;
  }

  @override
  Future<String> saveImage(File imageFile) async {
    await _initOnce();
    if (!await imageFile.exists()) {
      throw ArgumentError.value(
        imageFile.path,
        'imageFile',
        'File does not exist',
      );
    }
    final guid = const Uuid().v4();
    final ext = _safeExtension(imageFile.path);
    final fileName = '$guid$ext';
    final target = File(p.join(_imagesDir!.path, fileName));
    await imageFile.copy(target.path);
    return fileName;
  }

  @override
  Future<void> deleteImage(String imageGuid) async {
    await _initOnce();
    final safe = _sanitizeGuid(imageGuid);
    final f = File(p.join(_imagesDir!.path, safe));
    if (await f.exists()) {
      await f.delete();
    }
  }

  @override
  Future<void> deleteAllImages() async {
    await _initOnce();
    await for (final e in _imagesDir!.list(followLinks: false)) {
      try {
        await e.delete(recursive: true);
      } catch (_) {
        /* ignore partial failures */
      }
    }
  }

  // ---------- helpers ----------

  Future<void> _initOnce() async {
    if (_imagesDir != null) return; // fast path
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();
    try {
      final base = _baseDirOverride ?? await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, subdirName));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _imagesDir = dir;
      _initCompleter!.complete();
    } catch (e, st) {
      _initCompleter!.completeError(e, st);
      rethrow;
    } finally {
      // keep _initCompleter so concurrent waiters have a future; _imagesDir marks ready
    }
  }

  /// Reject anything that isn't a bare filename (defense-in-depth).
  static String _sanitizeGuid(String guid) {
    final g = guid.trim();
    if (g.isEmpty) {
      throw ArgumentError.value(guid, 'imageGuid', 'Empty GUID/filename');
    }

    // Normalize separators for checks.
    final n = g.replaceAll('\\', '/');

    // Disallow any path segments or parent refs.
    if (n.contains('/')) {
      throw ArgumentError.value(
        guid,
        'imageGuid',
        'Path separators are not allowed',
      );
    }
    if (n.contains('..')) {
      throw ArgumentError.value(
        guid,
        'imageGuid',
        'Parent directory reference not allowed',
      );
    }

    // Disallow obvious absolute-path patterns (extra safety).
    final absWin = RegExp(r'^[A-Za-z]:');
    if (n.startsWith('/') || absWin.hasMatch(n) || n.startsWith('\\\\')) {
      throw ArgumentError.value(
        guid,
        'imageGuid',
        'Absolute paths are not allowed',
      );
    }

    // Final sanity: ensure we’re dealing with just the basename.
    final base = p.basename(n);
    if (base != n) {
      throw ArgumentError.value(guid, 'imageGuid', 'Invalid GUID/filename');
    }
    return base;
  }

  static String _safeExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic'};
    return allowed.contains(ext) ? ext : '.jpg';
  }
}
