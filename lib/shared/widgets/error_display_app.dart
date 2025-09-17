import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'error_view.dart';

class ErrorDisplayApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final SentryId? sentryId;
  final Future<void> Function()? onRestart;

  const ErrorDisplayApp({
    super.key,
    required this.error,
    this.stackTrace,
    this.sentryId,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: ErrorView(
        appBarTitle: 'Critical Application Error',
        headline: 'Unable to start the app',
        description: 'A critical error occurred during initialization. The app cannot continue.',
        error: error,
        stackTrace: stackTrace,
        sentryId: sentryId,
        onRestart: onRestart,
      ),
    );
  }
}
