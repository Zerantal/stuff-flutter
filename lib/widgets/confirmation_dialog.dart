// lib/widgets/confirmation_dialog.dart
import 'package:flutter/material.dart';

class ConfirmationDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          danger
              ? FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(confirmText),
                )
              : FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmText),
                ),
        ],
      ),
    );
  }
}
