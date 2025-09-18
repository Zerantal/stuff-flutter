// lib/shared/widgets/bootstrap_error_app.dart
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'exception_error_panel.dart';

class BootstrapErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final SentryId? sentryId;

  const BootstrapErrorApp({super.key, required this.error, this.stackTrace, this.sentryId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: ExceptionErrorPanel(
        appBarTitle: 'Critical Application Error',
        headline: 'Unable to start the app',
        description: 'A critical error occurred during initialization. The app cannot continue.',
        error: error,
        stackTrace: stackTrace,
        extra: sentryId != null
            ? [
                Text(
                  'Sentry event ID: ${sentryId.toString()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]
            : null,
      ),
    );
  }
}
