// lib/services/temporary_file_service_interface.dart
import 'dart:io';

abstract class ITemporaryFileService {
  /// Creates a unique temporary directory for a session.
  /// The [sessionPrefix] helps in identifying the directory's purpose.
  Future<Directory> createSessionTempDir(String sessionPrefix);

  /// Copies a source file to the specified temporary directory.
  /// Returns the copied file.
  Future<File> copyToTempDir(File sourceFile, Directory tempDir);

  /// Deletes a file.
  Future<void> deleteFile(File file);

  /// Deletes a directory and all its contents.
  Future<void> deleteDirectory(Directory directory);
}
