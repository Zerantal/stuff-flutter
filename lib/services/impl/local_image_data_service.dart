import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/helpers/image_ref.dart';
import '../image_data_service_interface.dart';

/// Stores images locally under an app-owned directory and exposes GUID lookups.
/// - GUID == filename (uuid + original extension)
/// - getImage() returns ImageRef.file(...)
/// - saveImage() copies or moves (when deleteSource: true)
class LocalImageDataService extends IImageDataService {
  LocalImageDataService({
    String? subdirectoryName,
    Directory? rootOverride,
  })  : _subdir = subdirectoryName ?? 'images',
        _rootOverride = rootOverride;

  final Logger _log = Logger('LocalImageDataService');
  final String _subdir;
  final Directory? _rootOverride;
  final Uuid _uuid = const Uuid();

  Directory? _rootDir;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  /// Root folder on disk where images are stored.
  Directory get rootDir {
    final dir = _rootDir;
    if (dir == null) {
      throw StateError(
        'LocalImageDataService not initialized. Call init() before use.',
      );
    }
    return dir;
  }

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      Directory base;
      if (_rootOverride != null) {
        base = _rootOverride;
      } else {
        // Support dir keeps things out of user-visible "Documents" on desktop.
        base = await getApplicationSupportDirectory();
      }
      final Directory target = Directory(p.join(base.path, _subdir));
      if (!await target.exists()) {
        await target.create(recursive: true);
      }
      _rootDir = target;
      _initialized = true;
      _log.fine('Image store initialized at: ${target.path}');
    } catch (e, s) {
      _log.severe('Failed to initialize image store', e, s);
      rethrow;
    }
  }

  // ---- Queries --------------------------------------------------------------

  @override
  Future<ImageRef?> getImage(String imageGuid, {bool verifyExists = true}) async {
    if (!_initialized) await init();

    final safeGuid = _sanitizeGuid(imageGuid);

    final absPath = p.join(rootDir.path, safeGuid);

    if (!verifyExists) {
      return ImageRef.file(absPath);
    }

    try {
      final exists = await File(absPath).exists();
      if (!exists) return null;
      return ImageRef.file(absPath);
    } catch (e, s) {
      _log.warning('getImage("$imageGuid") failed', e, s);
      return null;
    }
  }

  // ---- Mutations ------------------------------------------------------------

  @override
  Future<String> saveImage(File imageFile, {bool deleteSource = false}) async {
    if (!_initialized) await init();

    if (!await imageFile.exists()) {
      throw ArgumentError.value(
        imageFile.path,
        'imageFile',
        'Source file does not exist',
      );
    }

    final ext = _normalizedExtension(imageFile.path);
    final guid = '${_uuid.v4()}$ext';
    final destPath = p.join(rootDir.path, guid);
    final destFile = File(destPath);

    // If somehow a collision occurs (extremely unlikely), regenerate.
    if (await destFile.exists()) {
      final altGuid = '${_uuid.v4()}$ext';
      final altDest = File(p.join(rootDir.path, altGuid));
      return _copyOrMove(imageFile, altDest, deleteSource: deleteSource).then((_) => altGuid);
    }

    await _copyOrMove(imageFile, destFile, deleteSource: deleteSource);
    return guid;
  }

  @override
  Future<void> deleteImage(String imageGuid) async {
    if (!_initialized) await init();

    final safeGuid = _sanitizeGuid(imageGuid);

    final path = p.join(rootDir.path, safeGuid);
    final f = File(path);
    try {
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e, s) {
      _log.warning('deleteImage("$imageGuid") failed', e, s);
      // Swallow—delete is best-effort.
    }
  }

  @override
  Future<void> deleteAllImages() async {
    if (!_initialized) await init();
    try {
      await for (final ent in rootDir.list(followLinks: false)) {
        if (ent is File) {
          try {
            await ent.delete();
          } catch (_) {
            // Best-effort.
          }
        }
      }
    } catch (e, s) {
      _log.warning('deleteAllImages failed', e, s);
    }
  }

  // ---- Helpers --------------------------------------------------------------

  String _normalizedExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic'};
    return allowed.contains(ext) ? ext : '.jpg';
  }

  /// Reject anything that isn't a bare filename (defense-in-depth).
  static String _sanitizeGuid(String guid) {
    final g = guid.trim();
    if (g.isEmpty) throw ArgumentError.value(guid, 'imageGuid', 'Empty GUID/filename');

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

  /// Copies or moves [src] to [dest].
  /// - When [deleteSource] is true: attempt a fast rename (move). If it fails
  ///   (e.g., across devices), fall back to copy + delete.
  /// - When [deleteSource] is false: copy only.
  Future<void> _copyOrMove(
      File src,
      File dest, {
        required bool deleteSource,
      }) async {
    if (deleteSource) {
      try {
        // Attempt a fast move first (same-volume rename).
        await src.rename(dest.path);
        return;
      } catch (_) {
        // Cross-device rename error—fall back to copy + delete
      }
      await src.copy(dest.path);
      try {
        await src.delete();
      } catch (_) {
        // Not fatal if we can't delete the source
      }
    } else {
      await src.copy(dest.path);
    }
  }
}
