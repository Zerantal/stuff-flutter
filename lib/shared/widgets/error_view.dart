import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Shared error view for bootstrap/runtime errors.
class ErrorView extends StatelessWidget {
  final String appBarTitle;
  final String headline;
  final String description;
  final Object error;
  final StackTrace? stackTrace;
  final SentryId? sentryId;
  final IconData icon;
  final Future<void> Function()? onRestart;

  const ErrorView({
    super.key,
    required this.appBarTitle,
    required this.headline,
    required this.description,
    required this.error,
    this.stackTrace,
    this.sentryId,
    this.icon = Icons.error_outline,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: theme.colorScheme.error, size: 72),
                    const SizedBox(height: 16),

                    Text(
                      headline,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Error summary card
                    Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(error.toString(), style: theme.textTheme.bodySmall),
                      ),
                    ),

                    // Optional stack trace
                    if (stackTrace != null) ...[
                      const SizedBox(height: 12),
                      ExpansionTile(
                        title: const Text('Show details'),
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              stackTrace.toString(),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text("Copy stack trace"),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: stackTrace.toString()));
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text("Stack trace copied")));
                            },
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ---- Actions ----
                    Wrap(
                      spacing: 12,
                      children: [
                        if (onRestart != null)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Restart'),
                            onPressed: () async {
                              await onRestart!();
                            },
                          ),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: Text(
                            (kIsWeb || Platform.isAndroid || Platform.isIOS) ? 'Close App' : 'Exit',
                          ),
                          onPressed: () {
                            if (kIsWeb) {
                              // Web cannot exit programmatically → just reload
                              // ignore: undefined_prefixed_name
                              SystemNavigator.pop(); // fallback, may just "pop" one view
                            } else {
                              exit(0);
                            }
                          },
                        ),
                      ],
                    ),

                    // Event ID if available
                    if (sentryId != null &&
                        sentryId.toString() != '00000000000000000000000000000000') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: SelectableText(
                              'Sentry event ID: ${sentryId.toString()}',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            tooltip: "Copy event ID",
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: sentryId.toString()));
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text("Event ID copied")));
                            },
                          ),
                        ],
                      ),
                    ],
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
