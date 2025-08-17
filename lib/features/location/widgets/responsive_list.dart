// lib/features/location/widgets/responsive_list.dart
import 'package:flutter/material.dart';

import '../../../domain/models/location_model.dart';
import '../viewmodels/locations_view_model.dart';
import 'grid_location_card.dart';
import 'location_card.dart';

/// Responsive list: list on phones, grid on wider screens.
class ResponsiveLocations extends StatelessWidget {
  const ResponsiveLocations({
    super.key,
    required this.items,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LocationListItem> items;
  final void Function(Location) onView;
  final void Function(Location) onEdit;
  final void Function(Location) onDelete;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useGrid = width >= 720;

    if (!useGrid) {
      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return LocationCard(
            location: item.location,
            images: item.images,
            onView: onView,
            onEdit: onEdit,
            onDelete: onDelete,
          );
        },
      );
    }

    final columns = width >= 1100 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 132,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return GridLocationCard(
          location: item.location,
          images: item.images,
          onView: onView,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }
}
