// lib/shared/widgets/edit_entity_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import 'confirmation_dialog.dart';

/// A reusable scaffold for entity editors (Location/Room/etc.)
/// Provides a consistent AppBar, Delete action, Save FAB, and optional
/// unsaved-changes confirmation on back.
class EditEntityScaffold extends StatelessWidget {
  const EditEntityScaffold({
    super.key,
    required this.title,
    required this.isCreate,
    required this.isBusy,
    this.isViewOnly = false,
    this.hasUnsavedChanges = false,
    this.onDelete,
    this.onEdit,
    required this.onSave,
    required this.body,
  });

  final String title;
  final bool isCreate;
  final bool isBusy;
  final bool isViewOnly;
  final bool hasUnsavedChanges;
  final Future<void> Function()? onDelete;
  final VoidCallback? onEdit;
  final Future<bool> Function() onSave;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // Only prompt discard if editing
        if (!isViewOnly && hasUnsavedChanges) {
          final discard = await ConfirmationDialog.show(
            context,
            title: 'Discard changes?',
            message: 'You have unsaved changes. Discard them and leave?',
            confirmText: 'Discard',
            cancelText: 'Cancel',
          );
          if (!context.mounted) return;

          if (discard == true && context.canPop()) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (!isViewOnly && onDelete != null)
              IconButton(
                key: const Key('delete_entity_btn'),
                tooltip: 'Delete',
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: isBusy
                    ? null
                    : () async {
                        final confirmDelete =
                            await ConfirmationDialog.show(
                              context,
                              title: 'Delete?',
                              message: 'This cannot be undone.',
                              confirmText: 'Delete',
                              cancelText: 'Cancel',
                            ) ??
                            false;

                        if (confirmDelete) {
                          await onDelete!();
                          if (context.mounted && context.canPop()) {
                            context.pop(true);
                          }
                        }
                      },
              ),
            if (isViewOnly && onEdit != null)
              IconButton(
                key: const Key('edit_entity_btn'),
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(padding: const EdgeInsets.all(AppSpacing.xs), child: body),
        ),
        floatingActionButton: isViewOnly
            ? null
            : FloatingActionButton.extended(
                key: const Key('save_entity_fab'),
                onPressed: isBusy
                    ? null
                    : () async {
                        final ok = await onSave();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? (isCreate ? 'Created' : 'Saved')
                                  : 'Please fix the errors and try again.',
                            ),
                          ),
                        );
                        if (ok && context.canPop()) {
                          context.pop(true);
                        }
                      },
                icon: const Icon(Icons.save_outlined),
                label: Text(isCreate ? 'Create' : 'Save'),
              ),
      ),
    );
  }
}
