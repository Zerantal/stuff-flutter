// lib/shared/widgets/runtime_error_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routing/app_routes.dart';
import 'exception_error_panel.dart';

class RuntimeErrorPage extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const RuntimeErrorPage({super.key, required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return ExceptionErrorPanel(
      appBarTitle: 'Unexpected Error',
      headline: 'Something went wrong',
      description: 'An unexpected error occurred. We’ve automatically reported this to our team.',
      error: error,
      stackTrace: stackTrace,
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.home),
          label: const Text('Return to Home'),
          onPressed: () {
            context.go(AppRoutes.locations.path);
          },
        ),
      ],
    );
  }
}
