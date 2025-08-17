// lib/features/location/widgets/location_action_menu.dart
import 'package:flutter/material.dart';

import '../../../domain/models/location_model.dart';

enum LocationAction { edit, view, delete }

class LocationActionsMenu extends StatelessWidget {
  const LocationActionsMenu({
    super.key,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
    required this.location,
  });

  final Function(Location) onEdit;
  final Function(Location) onView;
  final Function(Location) onDelete;
  final Location location;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LocationAction>(
      key: const ValueKey('location_action_menu'),
      tooltip: 'More',
      onSelected: (a) {
        switch (a) {
          case LocationAction.edit:
            onEdit(location);
            break;
          case LocationAction.view:
            onView(location);
            break;
          case LocationAction.delete:
            onDelete(location);
            break;
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: LocationAction.edit, key: ValueKey('edit_btn'), child: Text('Edit')),
        PopupMenuItem(value: LocationAction.view, key: ValueKey('view_btn'), child: Text('Open')),
        PopupMenuItem(
          key: ValueKey('delete_btn'),
          value: LocationAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
