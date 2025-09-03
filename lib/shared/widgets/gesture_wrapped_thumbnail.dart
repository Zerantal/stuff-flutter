// lib/shared/widgets/gesture_wrapped_thumbnail.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'image_thumb.dart';
import '../image/image_ref.dart';
import 'image_viewer/image_viewer_page.dart';

/// Generic tap-to-view thumbnail with optional Hero animation.
/// No Location/Room dependency — pass an entity id/name if you want stable hero tags
/// and a sensible export name in the viewer.
class GestureWrappedThumbnail extends StatelessWidget {
  const GestureWrappedThumbnail({
    super.key,
    required this.images,
    this.entityId,
    this.entityName,
    this.heroTag,
    this.width,
    this.height,
    this.size = 80,
    this.borderRadius = 8,
    this.placeholder,
  });

  /// Images to preview (first is used as the thumbnail).
  final List<ImageRef> images;

  /// Optional identifier to generate stable hero tags (e.g., a DB id).
  final String? entityId;

  /// Optional label used when exporting/sharing from the viewer.
  final String? entityName;

  /// Optional override for the first hero tag (otherwise auto-generated).
  final String? heroTag;

  /// Explicit width/height. If null, `size` is used for both.
  final double? width;
  final double? height;

  /// Fallback side length for a square thumbnail when width/height are omitted.
  final double size;

  /// Corner radius applied to the thumbnail.
  final double borderRadius;

  /// Optional placeholder image (defaults to the location placeholder asset).
  final ImageRef? placeholder;

  @override
  Widget build(BuildContext context) {
    Uuid uuid = const Uuid();
    final generatedUuid = uuid.v4();
    final preview = images.isNotEmpty ? images.first : null;
    final baseTag = 'ent_${entityId ?? generatedUuid}';
    final tags = List<String>.generate(images.length, (i) => '${baseTag}_img$i');
    if (tags.isNotEmpty && heroTag != null) tags[0] = heroTag!;

    final w = width ?? size;
    final h = height ?? size;

    Widget? placeholderWidget;
    if (placeholder != null) {
      placeholderWidget = buildImage(placeholder!, width: w, height: h, fit: BoxFit.cover);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: images.isEmpty
          ? null
          : () async {
              final nav = Navigator.of(context);
              await nav.push(
                MaterialPageRoute<void>(
                  builder: (_) => ImageViewerPage(
                    images: images,
                    initialIndex: 0,
                    heroTags: tags,
                    suggestedBaseName: entityName ?? 'Images',
                  ),
                ),
              );
            },
      child: Hero(
        tag: tags.isNotEmpty ? tags[0] : 'baseTag_empty$generatedUuid',
        child: ImageThumb(
          key: Key('thumb_${entityId ?? generatedUuid}'),
          image: preview, // null => placeholder shown
          width: w,
          height: h,
          borderRadius: BorderRadius.circular(borderRadius),
          placeholderWidget: placeholderWidget,
        ),
      ),
    );
  }
}
