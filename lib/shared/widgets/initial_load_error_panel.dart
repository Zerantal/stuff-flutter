// lib/shared/widgets/initial_load_error_panel.dart
import 'package:flutter/material.dart';
import 'error_message_panel.dart';

class InitialLoadErrorPanel extends StatelessWidget {
  const InitialLoadErrorPanel({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
    this.onClose,
  });

  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ErrorMessagePanel(
        icon: Icons.warning_amber_outlined,
        title: 'Failed to load',
        message: message,
        details: details,
        actions: [
          if (onRetry != null)
            FilledButton.icon(
              key: const ValueKey('initial_load_retry_btn'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          if (onClose != null)
            OutlinedButton.icon(
              key: const ValueKey('initial_load_close_btn'),
              onPressed: onClose,
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
        ],
      ),
    );
  }
}
