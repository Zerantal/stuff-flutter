// lib/shared/widgets/error_view.dart
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Shared error view for bootstrap/runtime errors.
class ErrorView extends StatelessWidget {
  final String appBarTitle;
  final String headline;
  final String description;
  final Object error;
  final StackTrace? stackTrace;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.appBarTitle,
    required this.headline,
    required this.description,
    required this.error,
    this.stackTrace,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.error, size: 72),
                const SizedBox(height: 16),
                Text(
                  headline,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Card(
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                if (stackTrace != null) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text('Show details'),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SelectableText(
                          stackTrace.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                FutureBuilder<SentryId>(
                  future: Sentry.captureException(error, stackTrace: stackTrace),
                  builder: (context, snapshot) {
                    final eventId =
                    snapshot.hasData ? snapshot.data.toString() : 'pending…';
                    return Text(
                      'Sentry event ID: $eventId',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
