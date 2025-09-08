// lib/shared/widgets/image_viewer/image_viewer_utils.dart
import '../../image/image_ref.dart';

/// Public helper to derive a default filename for a given [ImageRef].
/// This avoids relying on private state in [ImageViewerPage] and makes testing easier.
String defaultNameForRef(ImageRef ref, int index, {String? baseName}) {
  final base = baseName?.trim();
  if (base != null && base.isNotEmpty) return '${base}_$index.jpg';

  return switch (ref) {
    FileImageRef(:final path) => _nameFromPath(path) ?? 'image_$index.jpg',
    NetworkImageRef(:final url) => _nameFromUrl(url) ?? 'image_$index.jpg',
    AssetImageRef(:final assetName) => _nameFromPath(assetName) ?? 'image_$index.jpg',
    MemoryImageRef() => 'image_$index.jpg',
  };
}

String? _nameFromPath(String path) {
  final i = path.lastIndexOf(RegExp(r'[\/\\]'));
  return i >= 0 ? path.substring(i + 1) : null;
}

String? _nameFromUrl(String url) {
  final u = Uri.tryParse(url);
  final seg = u?.pathSegments.isNotEmpty == true ? u!.pathSegments.last : null;
  if (seg == null || seg.isEmpty) return null;
  return seg.split('?').first;
}
