// lib/services/temporary_file_service_interface.dart
import 'dart:io';

// TODO: fix comment
/// Abstraction for staging files under an app-scoped temporary *session* directory.
///
/// Typical lifecycle:
///   final temp = PathProviderTemporaryFileService();
///   await temp.init(sessionPrefix: 'imgpick');   // optional; lazy-inits on first use
///   final staged = await temp.copyToTemp(sourceFile);
///   await temp.deleteFile(staged);               // optional
///   await temp.clearSession();                   // cleanup when done
///   temp.dispose();                              // final safety net (sync)
abstract class ITemporaryFileService {
  // /// Prepare a unique session directory under the platform temp directory.
  // /// Implementations may *lazy-init* on first use if this is never called.
  // Future<void> init({String? sessionPrefix});
  //
  // /// The directory for this session. Throws if not yet initialized and lazy-init
  // /// is not supported by the implementation.
  // Directory get sessionDirectory;
  //
  // /// Copy [source] into the session directory and return the staged file.
  // /// If [fileName] is omitted, an implementation-defined unique name is used.
  // Future<File> copyToTemp(File source, {String? fileName});
  //
  // /// Delete a file if it exists. Should be resilient and *not* throw on ENOENT.
  // Future<void> deleteFile(File file);
  //
  // /// Delete the entire session directory (recursively) and release resources.
  // /// Should be safe to call multiple times.
  // Future<void> clearSession();
  //
  // /// Synchronous destructor-style cleanup. Should attempt to remove the session
  // /// directory (recursively) without throwing. Safe to call multiple times.
  // void dispose();

  // // --------- New interface ----------------

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
