// lib/features/location/widgets/location_card.dart
import 'package:flutter/material.dart';

import '../../../domain/models/location_model.dart';
import '../../../shared/image/image_ref.dart';
import 'gesture_wrapped_thumbnail.dart';
import 'location_action_menu.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.location,
    required this.images,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final Location location;
  final List<ImageRef> images;
  final void Function(Location) onView;
  final void Function(Location) onEdit;
  final void Function(Location) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('location_card_${location.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onView(location),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureWrappedThumbnail(
                location: location,
                images: images,
                heroTag: 'location_thumb_${location.id}',
                size: 80,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((location.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          location.description!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if ((location.address ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.address!,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LocationActionsMenu(
                onEdit: onEdit,
                onView: onView,
                onDelete: onDelete,
                location: location,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
