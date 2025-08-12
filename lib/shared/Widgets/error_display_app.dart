// lib/shared/Widgets/error_display_app.dart
import 'package:flutter/material.dart';

class ErrorDisplayApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const ErrorDisplayApp({super.key, required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Make sure this MaterialApp is simple and has no dependencies
      // on providers or services that might have failed to initialize.
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Critical Application Error'),
          backgroundColor: Colors.red,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  'A critical error occurred during app initialization, and the app cannot continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                if (stackTrace != null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'StackTrace:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(stackTrace.toString(), style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
