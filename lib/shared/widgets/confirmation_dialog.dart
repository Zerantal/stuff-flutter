// lib/shared/widgets/confirmation_dialog.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

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
        elevation: AppElevation.high,
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            key: const ValueKey('conf_dialog_cancel_btn'),
            child: Text(cancelText),
          ),
          danger
              ? FilledButton.tonalIcon(
                  key: const ValueKey('conf_dialog_confirm_btn'),
                  onPressed: () => context.pop(true),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(confirmText),
                )
              : FilledButton(
                  key: const ValueKey('conf_dialog_confirm_btn'),
                  onPressed: () => context.pop(true),
                  child: Text(confirmText),
                ),
        ],
      ),
    );
  }
}
