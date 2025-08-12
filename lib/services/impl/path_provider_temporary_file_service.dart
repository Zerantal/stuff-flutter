// lib/services/path_provider_temporary_file_service.dart
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../temporary_file_service_interface.dart';

final _log = Logger('PathProviderTemporaryFileService');
const _uuid = Uuid();

/// Stages files under `<system temp>/<prefix>-<uuid>/...`.
class PathProviderTemporaryFileService implements ITemporaryFileService {
  PathProviderTemporaryFileService({
    String sessionPrefix = 'temp',
    Directory?
    baseDirOverride, // for tests; if null, uses getTemporaryDirectory()
  }) : _sessionPrefix = sessionPrefix,
       _baseDirOverride = baseDirOverride;

  final String _sessionPrefix;
  final Directory? _baseDirOverride;
  Directory? _sessionDir;

  // Finalizer to clean up session dir as a last resort if dispose() wasn't called.
  static final Finalizer<String> _finalizer = Finalizer<String>((path) {
    try {
      final dir = Directory(path);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {
      // Best-effort; ignore failures.
    }
  });

  bool get _isInit => _sessionDir != null;

  @override
  Directory get sessionDirectory {
    final dir = _sessionDir;
    if (dir == null) {
      throw StateError('TemporaryFileService not initialized');
    }
    return dir;
  }

  @override
  Future<void> init({String? sessionPrefix}) async {
    if (_isInit) return;
    final base = _baseDirOverride ?? await getTemporaryDirectory();
    final prefix = sessionPrefix ?? _sessionPrefix;
    final name = '$prefix-${_uuid.v4()}';
    final dir = Directory(p.join(base.path, name));
    await dir.create(recursive: true);
    _sessionDir = dir;

    // Attach finalizer so the directory is cleaned if GC collects this object.
    _finalizer.attach(this, dir.path, detach: this);

    _log.info('Session temp dir: ${dir.path}');
  }

  Future<void> _ensureInit() => _isInit ? Future.value() : init();

  @override
  Future<File> copyToTemp(File source, {String? fileName}) async {
    await _ensureInit();
    // If the source is already inside the session directory, return as-is.
    final dir = sessionDirectory;
    final sourcePath = p.normalize(source.path);
    final dirPath = p.normalize(dir.path);
    if (p.isWithin(dirPath, sourcePath)) {
      return source;
    }

    final ext = p.extension(source.path);
    final name = fileName ?? '${_uuid.v4()}$ext';
    final destPath = p.join(dir.path, name);

    try {
      final copied = await source.copy(destPath);
      return copied;
    } catch (e, s) {
      _log.severe('Failed to copy to temp', e, s);
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        _log.finer('Deleted temp file: ${file.path}');
      }
    } catch (e, s) {
      _log.warning('Failed to delete temp file: ${file.path}', e, s);
    }
  }

  @override
  Future<void> clearSession() async {
    final dir = _sessionDir;
    if (dir == null) return;
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _log.info('Cleared session temp dir: ${dir.path}');
      }
    } catch (e, s) {
      _log.warning('Failed clearing session temp dir: ${dir.path}', e, s);
    } finally {
      _sessionDir = null;
      _finalizer.detach(this);
    }
  }

  @override
  void dispose() {
    final dir = _sessionDir;
    _sessionDir = null;
    // Ensure no finalizer action will run later.
    _finalizer.detach(this);
    if (dir == null) return;
    try {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        _log.info('Disposed session temp dir: ${dir.path}');
      }
    } catch (e, s) {
      _log.warning('Failed disposing session temp dir: ${dir.path}', e, s);
    }
  }

  @override
  Future<TempSession> startSession({String? label}) {
    // TODO: implement startSession
    throw UnimplementedError();
  }

  @override
  Future<int> sweepExpired({Duration maxAge}) {
    // TODO: implement sweepExpired
    throw UnimplementedError();
  }
}
