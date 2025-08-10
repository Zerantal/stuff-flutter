// Helper to distinguish image types in our list
import 'dart:io';

abstract class ImageIdentifier {}

// images that have been persisted to storage
class GuidIdentifier implements ImageIdentifier {
  final String guid; // "guid.ext" as returned by IImageDataService
  GuidIdentifier(this.guid);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuidIdentifier &&
          runtimeType == other.runtimeType &&
          guid == other.guid;

  @override
  int get hashCode => guid.hashCode;
}

// images that have not yet been persisted to storage
class TempFileIdentifier implements ImageIdentifier {
  final File file; // Temporary file
  TempFileIdentifier(this.file);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TempFileIdentifier &&
          runtimeType == other.runtimeType &&
          file.path == other.file.path;

  @override
  int get hashCode => file.path.hashCode;
}
