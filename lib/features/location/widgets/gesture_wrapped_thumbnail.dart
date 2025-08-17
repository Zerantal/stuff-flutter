// lib/features/location/widgets/gesture_wrapped_thumbnail.dart
import 'package:flutter/material.dart';

import '../../../domain/models/location_model.dart';
import '../../../shared/Widgets/image_thumb.dart';
import '../../../shared/image/image_ref.dart';
import '../../../shared/Widgets/image_viewer/image_viewer_page.dart';

class GestureWrappedThumbnail extends StatelessWidget {
  const GestureWrappedThumbnail({
    super.key,
    required this.location,
    required this.images,
    required this.heroTag,
    this.size = 80,
  });

  final Location location;
  final List<ImageRef> images;
  final String heroTag;
  final double size;

  @override
  Widget build(BuildContext context) {
    final preview = images.isNotEmpty ? images.first : null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: images.isEmpty
          ? null
          : () async {
              final nav = Navigator.of(context);
              // Build stable tags to match number of images; first tag = card hero
              final tags = List<String>.generate(images.length, (i) => 'loc_${location.id}_img$i');
              if (tags.isNotEmpty) tags[0] = heroTag;
              if (!context.mounted) return;
              await nav.push(
                MaterialPageRoute<void>(
                  builder: (_) => ImageViewerPage(
                    images: images,
                    initialIndex: 0,
                    heroTags: tags,
                    suggestedBaseName: location.name,
                  ),
                ),
              );
            },
      child: Hero(
        tag: heroTag,
        child: ImageThumb(
          key: Key('location_thumb_${location.id}'),
          image: preview, // null => placeholder shown
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(8),
          placeholderWidget: buildImage(
            const ImageRef.asset('assets/images/location_placeholder.jpg'),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
