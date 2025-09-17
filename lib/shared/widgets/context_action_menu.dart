// lib/shared/widgets/context_action_menu.dart
import 'package:flutter/material.dart';

enum ContextAction { edit, view, delete }

class ContextActionMenu extends StatelessWidget {
  const ContextActionMenu({
    super.key,
    this.onEdit,
    this.onView,
    this.onDelete,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final items = <Widget>[];

    if (onEdit != null) {
      items.add(MenuItemButton(
        key: const ValueKey('edit_btn'),
        onPressed: onEdit,
        leadingIcon: const Icon(Icons.edit_outlined),
        child: const Text('Edit'),
      ));
    }

    if (onView != null) {
      items.add(MenuItemButton(
        key: const ValueKey('view_btn'),
        onPressed: onView,
        leadingIcon: const Icon(Icons.open_in_new),
        child: const Text('View'),
      ));
    }

    if (onDelete != null) {
      items.add(MenuItemButton(
        key: const ValueKey('delete_btn'),
        onPressed: onDelete,
        leadingIcon: Icon(Icons.delete_outline, color: colorScheme.error),
        style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(colorScheme.error)),
        child: const Text('Delete'),
      ));
    }

    return MenuAnchor(
      consumeOutsideTap: true,
      builder: (context, controller, _) => IconButton(
        key: const ValueKey('context_action_menu'),
        tooltip: 'More',
        icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: items,
    );
  }
}
