// lib/shared/widgets/runtime_error_page.dart
import 'package:flutter/material.dart';
import 'error_view.dart';

class RuntimeErrorPage extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const RuntimeErrorPage({super.key, required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return ErrorView(
      appBarTitle: 'Unexpected Error',
      headline: 'Something went wrong',
      description: 'An unexpected error occurred. We’ve automatically reported this to our team.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
