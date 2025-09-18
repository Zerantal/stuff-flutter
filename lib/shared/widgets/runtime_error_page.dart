// lib/shared/widgets/runtime_error_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../app/bootstrap.dart';
import 'exception_error_panel.dart';

class RuntimeErrorPage extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final SentryId? sentryId;

  const RuntimeErrorPage({super.key, required this.error, this.stackTrace, this.sentryId});

  @override
  Widget build(BuildContext context) {
    final core = context.read<AppCore>();
    final theme = Theme.of(context);

    return ExceptionErrorPanel(
      appBarTitle: 'Unexpected Error',
      headline: 'Something went wrong',
      description: 'An unexpected error occurred. We’ve automatically reported this to our team.',
      error: error,
      stackTrace: stackTrace,
      extra: [
        if (sentryId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sentry event ID: ${sentryId.toString()}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
      actions: [
        FilledButton.icon(
          key: const ValueKey('runtime_restart_btn'),
          onPressed: () => onRestart(core),
          icon: const Icon(Icons.refresh),
          label: const Text('Restart App'),
        ),
      ],
    );
  }
}
