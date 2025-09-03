// lib/shared/widgets/image_viewer/image_viewer_page.dart
import 'dart:io' show File, HttpClient, Platform;

import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';

// Desktop-only import (not used on mobile)
import 'package:file_selector/file_selector.dart' as fs;

import '../../image/image_ref.dart';
import '../../image/mobile_saver.dart'; // Android MediaStore via MethodChannel
// Conditional web saver (no-ops off web)
import 'image_viewer_save_stub.dart' if (dart.library.html) 'image_viewer_save_web.dart' as websave;

final Logger _log = Logger('ImageViewerPage');

/// Full-screen image viewer for one or more images.
/// - Swipe horizontally to switch images (PageView).
/// - Pinch-to-zoom each page (InteractiveViewer).
/// - App bar actions operate on the *current* image.
/// - Optional heroTags for smooth transitions from thumbnails.
///
/// Saving behavior:
/// - Android: writes to Photos/Gallery via MobileSaver (MediaStore).
/// - Desktop: Save As dialog (file_selector).
/// - Web: triggers browser download.
/// - iOS (no native hook here): falls back to Share sheet.
class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTags,
    this.suggestedBaseName, // e.g. "LocationName"
  }) : assert(heroTags == null || heroTags.length == images.length);

  /// Images to display.
  final List<ImageRef> images;

  /// Initial page index.
  final int initialIndex;

  /// Optional per-image hero tags (same length as images).
  final List<String>? heroTags;

  /// If provided, downloads will default to "base_n.jpg".
  final String? suggestedBaseName;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late final PageController _pageController;
  late int _index;
  bool _chromeVisible = true; // tap to toggle UI chrome (optional nicety)

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ImageRef get _current => widget.images[_index];

  String _defaultNameFor(int i) {
    // Build a nice default name for saving/sharing.
    final base = widget.suggestedBaseName?.trim();
    if (base != null && base.isNotEmpty) return '${base}_$i.jpg';
    // Try to infer from ref
    final ref = widget.images[i];
    return switch (ref) {
      FileImageRef(:final path) => _nameFromPath(path) ?? 'image_$i.jpg',
      NetworkImageRef(:final url) => _nameFromUrl(url) ?? 'image_$i.jpg',
      AssetImageRef(:final assetName) => _nameFromPath(assetName) ?? 'image_$i.jpg',
      MemoryImageRef() => 'image_$i.jpg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final showDots = widget.images.length > 1;

    final appBar = AppBar(
      title: Text('${_index + 1} / ${widget.images.length}'),
      actions: [
        IconButton(
          tooltip: 'Save to device',
          icon: const Icon(Icons.download_outlined),
          onPressed: () => _saveToDevice(context),
        ),
        IconButton(
          tooltip: 'Share',
          icon: const Icon(Icons.ios_share_outlined),
          onPressed: () => _share(context),
        ),
      ],
    );

    final pageView = PageView.builder(
      controller: _pageController,
      itemCount: widget.images.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (context, i) {
        final ref = widget.images[i];
        final viewer = GestureDetector(
          onTap: () => setState(() => _chromeVisible = !_chromeVisible),
          behavior: HitTestBehavior.opaque,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(child: buildImage(ref, fit: BoxFit.contain)),
          ),
        );

        final tag = widget.heroTags != null ? widget.heroTags![i] : null;
        if (tag != null && tag.isNotEmpty) {
          return Hero(tag: tag, child: viewer);
        }
        return viewer;
      },
    );

    final dots = _PageDots(count: widget.images.length, index: _index);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _chromeVisible ? appBar : null,
      body: Stack(
        children: [
          pageView,
          if (_chromeVisible && showDots)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: SafeArea(top: false, child: Center(child: dots)),
            ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context); // capture
    try {
      final (bytes, name) = await _resolveBytesAndName(
        _current,
        fallbackName: _defaultNameFor(_index + 1),
      );
      if (bytes != null) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(bytes, name: name)],
            text: 'Photo',
          ),
        );
      } else {
        await _shareFallback(_current);
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Share failed')));
    }
  }

  Future<void> _saveToDevice(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final (bytes, name) = await _resolveBytesAndName(
        _current,
        fallbackName: _defaultNameFor(_index + 1),
      );

      if (kIsWeb) {
        // Browser download
        if (bytes != null) {
          await websave.saveBytesToDownloadsWeb(bytes, name);
          messenger.showSnackBar(const SnackBar(content: Text('Download started')));
        } else {
          await _shareFallback(_current);
          messenger.showSnackBar(const SnackBar(content: Text('Opened share sheet')));
        }
        return;
      }

      if (Platform.isAndroid) {
        if (bytes != null) {
          final ok = await MobileSaver.saveToGallery(bytes, fileName: name, album: 'Stuff');
          messenger.showSnackBar(SnackBar(content: Text(ok ? 'Saved to Photos' : 'Save failed')));
        } else {
          await _shareFallback(_current);
          messenger.showSnackBar(const SnackBar(content: Text('Opened share sheet')));
        }
        return;
      }

      if (Platform.isIOS) {
        // (TODO: add a native PHPhotoLibrary saver later.)
        if (bytes != null) {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile.fromData(bytes, name: name)],
              text: 'Photo',
            ),
          );
        } else {
          await _shareFallback(_current);
        }
        messenger.showSnackBar(const SnackBar(content: Text('Opened share sheet')));
        return;
      }

      // Desktop: Save As
      if (bytes != null) {
        final loc = await fs.getSaveLocation(suggestedName: name);
        if (loc == null) return;
        final xf = fs.XFile.fromData(bytes, name: name);
        await xf.saveTo(loc.path);
        messenger.showSnackBar(const SnackBar(content: Text('Saved')));
      } else {
        await _shareFallback(_current);
        messenger.showSnackBar(const SnackBar(content: Text('Opened share sheet')));
      }
    } catch (e, s) {
      messenger.showSnackBar(const SnackBar(content: Text('Save failed')));
      _log.severe('Error saving image', e, s);
    }
  }

  Future<(Uint8List?, String)> _resolveBytesAndName(
    ImageRef ref, {
    required String fallbackName,
  }) async {
    switch (ref) {
      case FileImageRef(:final path):
        final data = await File(path).readAsBytes();
        return (data, _nameFromPath(path) ?? fallbackName);

      case MemoryImageRef(:final bytes):
        return (bytes, fallbackName);

      case AssetImageRef(:final assetName):
        final bd = await rootBundle.load(assetName);
        return (bd.buffer.asUint8List(), _nameFromPath(assetName) ?? fallbackName);

      case NetworkImageRef(:final url):
        if (kIsWeb) {
          return (null, _nameFromUrl(url) ?? fallbackName);
        }
        try {
          final http = HttpClient();
          final req = await http.getUrl(Uri.parse(url));
          final res = await req.close();
          if (res.statusCode >= 200 && res.statusCode < 300) {
            final bytes = await consolidateHttpClientResponseBytes(res);
            return (bytes, _nameFromUrl(url) ?? fallbackName);
          }
        } catch (_) {
          // ignore → use fallback
        }
        return (null, _nameFromUrl(url) ?? fallbackName);
    }
  }

  Future<void> _shareFallback(ImageRef image) async {
    if (image is FileImageRef) {
      await SharePlus.instance.share(ShareParams(files: [XFile(image.path)], text: 'Photo'));
      return;
    }
    if (image is NetworkImageRef) {
      await SharePlus.instance.share(ShareParams(uri: Uri.parse(image.url), text: 'Photo'));
      return;
    }
    if (image is MemoryImageRef) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(image.bytes, name: 'image.jpg')],
          fileNameOverrides: ['image.jpg'],
          text: 'Photo',
        ),
      );
      return;
    }
    if (image is AssetImageRef) {
      final bd = await rootBundle.load(image.assetName);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bd.buffer.asUint8List(), name: 'image.jpg')],
          text: 'Photo',
        ),
      );
      //Share.shareXFiles([XFile.fromData(bd.buffer.asUint8List(), name: 'image.jpg')]);
    }
  }

  String? _nameFromPath(String path) {
    final i = path.lastIndexOf(RegExp(r'[\/\\]'));
    return i >= 0 ? path.substring(i + 1) : null;
  }

  String? _nameFromUrl(String url) {
    // Strip query params if present
    final u = Uri.tryParse(url);
    final seg = u?.pathSegments.isNotEmpty == true ? u!.pathSegments.last : null;
    if (seg == null || seg.isEmpty) return null;
    return seg.split('?').first;
  }
}

/// Tiny dots indicator to avoid a dependency.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 18 : 8,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
