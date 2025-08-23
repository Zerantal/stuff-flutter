// lib/shared/widgets/context_action_menu.dart
import 'package:flutter/material.dart';

enum ContextAction { edit, view, delete }

class ContextActionMenu<E> extends StatelessWidget {
  const ContextActionMenu({
    super.key,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      consumeOutsideTap: true,
      builder: (context, controller, _) => IconButton(
        key: const ValueKey('context_action_menu'),
        tooltip: 'More',
        icon: const Icon(Icons.more_vert),
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          key: const ValueKey('edit_btn'),
          onPressed: onEdit,
          leadingIcon: const Icon(Icons.edit_outlined),
          child: const Text('Edit'),
        ),
        MenuItemButton(
          key: const ValueKey('view_btn'),
          onPressed: onView,
          leadingIcon: const Icon(Icons.open_in_new),
          child: const Text('View'),
        ),
        MenuItemButton(
          key: const ValueKey('delete_btn'),
          onPressed: onDelete,
          leadingIcon: const Icon(Icons.delete_outline, color: Colors.red),
          style: const ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.red)),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
