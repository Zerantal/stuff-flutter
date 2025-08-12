// lib/services/impl/path_provider_temporary_file_service.dart
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../temporary_file_service_interface.dart';

final _log = Logger('PathProviderTemporaryFileService');

/// A path_provider-backed temporary file service that stages picked files
/// into an app-private “session” directory (under Application Support).
///
/// - Use [startSession] at page-entry to get a [TempSession].
/// - During edits, call [TempSession.importFile] for each picked image.
/// - On save, persist files to your permanent store (e.g., via IImageDataService),
///   passing `deleteSource: true` so they are moved out of the session.
/// - On cancel, call [TempSession.dispose(deleteContents: true)] to clean up.
/// - Optionally call [sweepExpired] on app start to remove orphaned sessions.
class PathProviderTemporaryFileService implements ITemporaryFileService {
  PathProviderTemporaryFileService({String stagingFolderName = 'staging', Directory? rootOverride})
    : _stagingFolderName = stagingFolderName,
      _rootOverride = rootOverride;

  final String _stagingFolderName;
  final Directory? _rootOverride;
  final Uuid _uuid = const Uuid();

  /// Root directory for staging sessions: `<app-support>/<stagingFolderName>/`
  Future<Directory> _stagingRoot() async {
    if (_rootOverride != null) {
      final d = Directory(p.join(_rootOverride.path, _stagingFolderName));
      if (!await d.exists()) await d.create(recursive: true);
      return d;
    }
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, _stagingFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<TempSession> startSession({String? label}) async {
    final root = await _stagingRoot();
    final safe = _sanitizeLabel(label);
    final id = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
    final name = safe.isEmpty ? id : '$safe-$id';
    final dir = Directory(p.join(root.path, name));
    await dir.create(recursive: true);
    _log.fine('Started temp session at ${dir.path}');
    return _PathProviderTempSession(dir, _log);
  }

  @override
  Future<int> sweepExpired({Duration maxAge = const Duration(days: 3)}) async {
    final root = await _stagingRoot();
    var deleted = 0;
    try {
      await for (final ent in root.list(followLinks: false)) {
        if (ent is! Directory) continue;
        try {
          final stat = await ent.stat();
          final age = DateTime.now().difference(stat.modified);
          if (age > maxAge) {
            await ent.delete(recursive: true);
            deleted++;
          }
        } catch (e, s) {
          _log.warning('Failed to consider/delete ${ent.path}', e, s);
        }
      }
    } catch (e, s) {
      _log.warning('sweepExpired aborted at root ${root.path}', e, s);
    }
    if (deleted > 0) {
      _log.fine('sweepExpired removed $deleted expired session(s)');
    }
    return deleted;
  }

  String _sanitizeLabel(String? raw) {
    if (raw == null) return '';
    // allow [a-zA-Z0-9-_], collapse others to _
    final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9\-_]+'), '_').trim();
    return cleaned.replaceAll(RegExp(r'_+'), '_');
  }
}

class _PathProviderTempSession implements TempSession {
  _PathProviderTempSession(this._dir, this._log);

  final Directory _dir;
  final Logger _log;

  @override
  Directory get dir => _dir;

  @override
  Future<File> importFile(File src, {String? preferredName, bool deleteSource = false}) async {
    if (!await src.exists()) {
      throw ArgumentError.value(src.path, 'src', 'Source file does not exist');
    }
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
    }

    final dest = await _allocateDestination(src, preferredName: preferredName);

    if (deleteSource) {
      // Try a fast rename (works if same volume), else copy+delete
      try {
        await src.rename(dest.path);
        return dest;
      } catch (_) {
        // fall through to copy+delete
      }
      await src.copy(dest.path);
      try {
        await src.delete();
      } catch (_) {
        // best-effort; not fatal
      }
      return dest;
    } else {
      await src.copy(dest.path);
      return dest;
    }
  }

  @override
  Future<void> dispose({bool deleteContents = true}) async {
    if (!await _dir.exists()) return;
    try {
      if (deleteContents) {
        await _dir.delete(recursive: true);
        _log.fine('Disposed temp session at ${_dir.path}');
      } else {
        _log.finer('Session disposed without deleting contents: ${_dir.path}');
      }
    } catch (e, s) {
      _log.warning('Failed to dispose session at ${_dir.path}', e, s);
    }
  }

  // ---- helpers --------------------------------------------------------------

  Future<File> _allocateDestination(File src, {String? preferredName}) async {
    final baseName = _candidateNameFor(src, preferredName: preferredName);
    var candidate = File(p.join(_dir.path, baseName));

    if (!await candidate.exists()) return candidate;

    // Ensure uniqueness by suffixing (-1), (-2), ...
    final name = p.basenameWithoutExtension(baseName);
    final ext = p.extension(baseName);
    var i = 1;
    while (await candidate.exists()) {
      candidate = File(p.join(_dir.path, '$name-$i$ext'));
      i++;
    }
    return candidate;
  }

  String _candidateNameFor(File src, {String? preferredName}) {
    final raw = (preferredName ?? p.basename(src.path)).trim();
    if (raw.isEmpty) {
      return _fallbackNameFor(src.path);
    }
    // Strip any path segments the caller may have passed
    final only = p.basename(raw);
    // Guard against files without extensions: keep original extension if any
    final ext = p.extension(only);
    if (ext.isEmpty) {
      final srcExt = p.extension(src.path);
      if (srcExt.isNotEmpty) return '$only$srcExt';
    }
    return only;
  }

  String _fallbackNameFor(String srcPath) {
    final ts = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\.]'), '-');
    final ext = p.extension(srcPath);
    return 'import_$ts${ext.isEmpty ? '.jpg' : ext}';
  }
}

// /// Stages files under `<system temp>/<prefix>-<uuid>/...`.
// class PathProviderTemporaryFileService implements ITemporaryFileService {
//   PathProviderTemporaryFileService({
//     String sessionPrefix = 'temp',
//     Directory? baseDirOverride, // for tests; if null, uses getTemporaryDirectory()
//   })  : _sessionPrefix = sessionPrefix,
//         _baseDirOverride = baseDirOverride;
//
//   final String _sessionPrefix;
//   final Directory? _baseDirOverride;
//   Directory? _sessionDir;
//
//   // Finalizer to clean up session dir as a last resort if dispose() wasn't called.
//   static final Finalizer<String> _finalizer = Finalizer<String>((path) {
//     try {
//       final dir = Directory(path);
//       if (dir.existsSync()) {
//         dir.deleteSync(recursive: true);
//       }
//     } catch (_) {
//       // Best-effort; ignore failures.
//     }
//   });
//
//   bool get _isInit => _sessionDir != null;
//
//   @override
//   Directory get sessionDirectory {
//     final dir = _sessionDir;
//     if (dir == null) {
//       throw StateError('TemporaryFileService not initialized');
//     }
//     return dir;
//   }
//
//   @override
//   Future<void> init({String? sessionPrefix}) async {
//     if (_isInit) return;
//     final base = _baseDirOverride ?? await getTemporaryDirectory();
//     final prefix = sessionPrefix ?? _sessionPrefix;
//     final name = '$prefix-${_uuid.v4()}';
//     final dir = Directory(p.join(base.path, name));
//     await dir.create(recursive: true);
//     _sessionDir = dir;
//
//     // Attach finalizer so the directory is cleaned if GC collects this object.
//     _finalizer.attach(this, dir.path, detach: this);
//
//     _log.info('Session temp dir: ${dir.path}');
//   }
//
//   Future<void> _ensureInit() => _isInit ? Future.value() : init();
//
//   @override
//   Future<File> copyToTemp(File source, {String? fileName}) async {
//     await _ensureInit();
//     // If the source is already inside the session directory, return as-is.
//     final dir = sessionDirectory;
//     final sourcePath = p.normalize(source.path);
//     final dirPath = p.normalize(dir.path);
//     if (p.isWithin(dirPath, sourcePath)) {
//       return source;
//     }
//
//     final ext = p.extension(source.path);
//     final name = fileName ?? '${_uuid.v4()}$ext';
//     final destPath = p.join(dir.path, name);
//
//     try {
//       final copied = await source.copy(destPath);
//       return copied;
//     } catch (e, s) {
//       _log.severe('Failed to copy to temp', e, s);
//       rethrow;
//     }
//   }
//
//   @override
//   Future<void> deleteFile(File file) async {
//     try {
//       if (await file.exists()) {
//         await file.delete();
//         _log.finer('Deleted temp file: ${file.path}');
//       }
//     } catch (e, s) {
//       _log.warning('Failed to delete temp file: ${file.path}', e, s);
//     }
//   }
//
//   @override
//   Future<void> clearSession() async {
//     final dir = _sessionDir;
//     if (dir == null) return;
//     try {
//       if (await dir.exists()) {
//         await dir.delete(recursive: true);
//         _log.info('Cleared session temp dir: ${dir.path}');
//       }
//     } catch (e, s) {
//       _log.warning('Failed clearing session temp dir: ${dir.path}', e, s);
//     } finally {
//       _sessionDir = null;
//       _finalizer.detach(this);
//     }
//   }
//
//   @override
//   void dispose() {
//     final dir = _sessionDir;
//     _sessionDir = null;
//     // Ensure no finalizer action will run later.
//     _finalizer.detach(this);
//     if (dir == null) return;
//     try {
//       if (dir.existsSync()) {
//         dir.deleteSync(recursive: true);
//         _log.info('Disposed session temp dir: ${dir.path}');
//       }
//     } catch (e, s) {
//       _log.warning('Failed disposing session temp dir: ${dir.path}', e, s);
//     }
//   }
// }
