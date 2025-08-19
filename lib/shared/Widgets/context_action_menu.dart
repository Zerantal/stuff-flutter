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
    return PopupMenuButton<ContextAction>(
      key: const ValueKey('context_action_menu'),
      tooltip: 'More',
      onSelected: (a) {
        switch (a) {
          case ContextAction.edit:
            onEdit?.call();
            break;
          case ContextAction.view:
            onView?.call();
            break;
          case ContextAction.delete:
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: ContextAction.edit, key: ValueKey('edit_btn'), child: Text('Edit')),
        PopupMenuItem(value: ContextAction.view, key: ValueKey('view_btn'), child: Text('Open')),
        PopupMenuItem(
          key: ValueKey('delete_btn'),
          value: ContextAction.delete,
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
