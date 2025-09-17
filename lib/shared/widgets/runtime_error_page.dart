import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'error_view.dart';

class RuntimeErrorPage extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final SentryId? sentryId;
  final Future<void> Function()? onRestart;

  const RuntimeErrorPage({
    super.key,
    required this.error,
    this.stackTrace,
    this.sentryId,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      appBarTitle: 'Unexpected Error',
      headline: 'Something went wrong',
      description: 'An unexpected error occurred. We’ve automatically reported this to our team.',
      error: error,
      stackTrace: stackTrace,
      sentryId: sentryId,
      onRestart: onRestart,
    );
  }
}
