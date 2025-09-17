// lib/shared/widgets/error_display_app.dart
import 'package:flutter/material.dart';
import 'error_view.dart';

class ErrorDisplayApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const ErrorDisplayApp({super.key, required this.error, this.stackTrace});

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
        description:
        'A critical error occurred during initialization. The app cannot continue.',
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
