// lib/features/location/widgets/grid_location_card.dart
import 'package:flutter/material.dart';

import '../../../domain/models/location_model.dart';
import '../../../shared/image/image_ref.dart';
import 'gesture_wrapped_thumbnail.dart';
import 'location_action_menu.dart';

class GridLocationCard extends StatelessWidget {
  const GridLocationCard({
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onView(location),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GestureWrappedThumbnail(
                location: location,
                images: images,
                heroTag: 'loc_${location.id}',
                size: 80,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      location.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((location.address ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
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
