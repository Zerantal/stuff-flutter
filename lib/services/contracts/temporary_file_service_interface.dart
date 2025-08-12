// lib/services/contracts/temporary_file_service_interface.dart
import 'dart:io';

/// - Use [startSession] at page-entry to get a [TempSession].
/// - During edits, call [TempSession.importFile] for each picked image.
/// - On save, persist files to your permanent store (e.g., via IImageDataService),
///   passing `deleteSource: true` so they are moved out of the session.
/// - On cancel, call [TempSession.dispose(deleteContents: true)] to clean up.
/// - Optionally call [sweepExpired] on app start to remove orphaned sessions.
abstract class ITemporaryFileService {
  /// Creates a new staging session under Application Support (not OS cache).
  Future<TempSession> startSession({String? label});

  /// Best-effort cleanup of old sessions.
  Future<int> sweepExpired({Duration maxAge});
}

abstract class TempSession {
  Directory get dir;

  /// Import a picked file into this session (copy or move).
  Future<File> importFile(File src, {String? preferredName, bool deleteSource = true});

  /// Dispose of this session; optionally delete contents.
  Future<void> dispose({bool deleteContents = true});
}
