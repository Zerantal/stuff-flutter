// lib/shared/widgets/error_message_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared panel for displaying errors in-app (runtime/bootstrap/init).
class ErrorMessagePanel extends StatelessWidget {
  const ErrorMessagePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.details,
    this.actions,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? details;
  final List<Widget>? actions;
  final List<Widget>? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 72, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  if (details != null) ...[
                    const Divider(height: 24),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          'View technical details',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              details!,
                              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy stack trace'),
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: details!));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Stack trace copied')),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (extra != null) ...[const SizedBox(height: 16), ...extra!],
                  if (actions != null) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: actions!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
