// lib/services/path_provider_temporary_file_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import '../temporary_file_service_interface.dart';

final Logger _logger = Logger('PathProviderTemporaryFileService');
const Uuid _uuid = Uuid();

class PathProviderTemporaryFileService implements ITemporaryFileService {
  @override
  Future<Directory> createSessionTempDir(String sessionPrefix) async {
    try {
      final Directory baseTempDir = await getTemporaryDirectory();
      final String uniqueId = _uuid.v4().substring(0, 8);
      final Directory sessionDir = Directory(
        p.join(baseTempDir.path, '${sessionPrefix}_$uniqueId'),
      );

      if (!await sessionDir.exists()) {
        await sessionDir.create(recursive: true);
        _logger.info("Created session temporary directory: ${sessionDir.path}");
      } else {
        _logger.info(
          "Session temporary directory already exists: ${sessionDir.path}",
        );
      }
      return sessionDir;
    } catch (e, s) {
      _logger.severe('Failed to create session temporary directory: $e', s);
      rethrow;
    }
  }

  @override
  Future<File> copyToTempDir(File sourceFile, Directory tempDir) async {
    try {
      if (!await tempDir.exists()) {
        _logger.warning(
          "Target temporary directory ${tempDir.path} does not exist. Attempting to create.",
        );
        await tempDir.create(recursive: true);
      }
      final String fileName = p.basename(sourceFile.path);
      final String destinationPath = p.join(tempDir.path, fileName);
      final File copiedFile = await sourceFile.copy(destinationPath);
      _logger.info("Copied ${sourceFile.path} to ${copiedFile.path}");
      return copiedFile;
    } catch (e, s) {
      _logger.severe(
        'Failed to copy file ${sourceFile.path} to temp directory ${tempDir.path}: $e',
        s,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        _logger.info("Deleted temporary file: ${file.path}");
      } else {
        _logger.info("Temporary file to delete did not exist: ${file.path}");
      }
    } catch (e, s) {
      _logger.warning('Failed to delete temporary file ${file.path}: $e', s);
      // Decide if this should rethrow based on severity
    }
  }

  @override
  Future<void> deleteDirectory(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        _logger.info("Deleted temporary directory: ${directory.path}");
      } else {
        _logger.info(
          "Temporary directory to delete did not exist: ${directory.path}",
        );
      }
    } catch (e, s) {
      _logger.warning(
        'Failed to delete temporary directory ${directory.path}: $e',
        s,
      );
      // Decide if this should rethrow
    }
  }
}
