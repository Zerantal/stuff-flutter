// lib/widgets/confirmation_dialog.dart
import 'package:flutter/material.dart';

/// Shows a confirmation dialog.
///
/// Returns `true` if the user taps the confirm button, `false` if they tap the
/// cancel button, and `null` if the dialog is dismissed by other means (e.g.,
/// back button if barrierDismissible is true, though it's set to false by default here).
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color? confirmButtonColor,
  bool barrierDismissible =
      false, // Set to true to allow dismissing by tapping outside
  // By default, user must tap a button.
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: Text(cancelText),
            onPressed: () {
              Navigator.of(dialogContext).pop(false); // Indicates cancellation
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor:
                  confirmButtonColor, // Apply custom color if provided
            ),
            child: Text(confirmText),
            onPressed: () {
              Navigator.of(dialogContext).pop(true); // Indicates confirmation
            },
          ),
        ],
      );
    },
  );
}
