// lib/shared/widgets/initial_load_error_panel.dart
import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(height: 8),
                    Text('Failed to load', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(message, textAlign: TextAlign.center),
                    if (details != null) ...[
                      const SizedBox(height: 8),
                      Text(details!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (onRetry != null)
                          FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        if (onRetry != null && onClose != null) const SizedBox(width: 8),
                        if (onClose != null)
                          OutlinedButton.icon(
                            onPressed: onClose,
                            icon: const Icon(Icons.close),
                            label: const Text('Close'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
