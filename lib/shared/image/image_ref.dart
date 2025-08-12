// lib/shared/image/image_ref.dart
// Tiny helper for representing image sources in a UI-agnostic way.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Platform-specific file provider
import 'src/image_file_provider_stub.dart'
    if (dart.library.io) 'src/image_file_provider_io.dart'
    as fileprov;

/// UI-agnostic image reference your ViewModel can return.
/// The view converts this to an ImageProvider or Image widget.
sealed class ImageRef {
  const ImageRef();
  const factory ImageRef.file(String path) = FileImageRef;
  const factory ImageRef.network(String url) = NetworkImageRef;
  const factory ImageRef.memory(Uint8List bytes) = MemoryImageRef;
  const factory ImageRef.asset(String assetName, {AssetBundle? bundle, String? package}) =
      AssetImageRef;
}

class FileImageRef extends ImageRef {
  final String path;
  const FileImageRef(this.path);
}

class NetworkImageRef extends ImageRef {
  final String url;
  const NetworkImageRef(this.url);
}

class MemoryImageRef extends ImageRef {
  final Uint8List bytes;
  const MemoryImageRef(this.bytes);
}

class AssetImageRef extends ImageRef {
  final String assetName;
  final AssetBundle? bundle;
  final String? package;
  const AssetImageRef(this.assetName, {this.bundle, this.package});
}

/// Convert an [ImageRef] into an [ImageProvider].
ImageProvider providerFor(ImageRef ref, {int? cacheWidth, int? cacheHeight, double scale = 1.0}) {
  final ImageProvider base = switch (ref) {
    FileImageRef(:final path) => _fileImage(path, scale: scale),
    NetworkImageRef(:final url) => NetworkImage(url, scale: scale),
    MemoryImageRef(:final bytes) => MemoryImage(bytes, scale: scale),
    AssetImageRef(:final assetName, :final bundle, :final package) => AssetImage(
      assetName,
      bundle: bundle,
      package: package,
    ),
  };

  // FileImage doesn't have cacheWidth/cacheHeight; wrap when requested.
  if (cacheWidth != null || cacheHeight != null) {
    return ResizeImage(base, width: cacheWidth, height: cacheHeight);
  }
  return base;
}

ImageProvider _fileImage(String path, {double scale = 1.0}) =>
    fileprov.fileImage(path, scale: scale);

/// Convenience widget builder for quickly rendering an [ImageRef].
Widget buildImage(
  ImageRef ref, {
  double? width,
  double? height,
  BoxFit? fit,
  AlignmentGeometry alignment = Alignment.center,
  FilterQuality filterQuality = FilterQuality.medium,
  int? cacheWidth,
  int? cacheHeight,
  Widget? loadingWidget,
  Widget? errorWidget,
}) {
  final provider = providerFor(ref, cacheWidth: cacheWidth, cacheHeight: cacheHeight);

  return Image(
    image: provider,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    filterQuality: filterQuality,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return loadingWidget ??
          const SizedBox(
            width: 20,
            height: 20,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
    },
    errorBuilder: (context, error, stack) {
      return errorWidget ??
          const Center(
            child: Text(
              'Image failed to load',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          );
    },
  );
}
