// lib/shared/widgets/exception_error_panel.dart
import 'package:flutter/material.dart';
import 'error_message_panel.dart';

/// Shared error view for bootstrap/runtime errors.
class ExceptionErrorPanel extends StatelessWidget {
  final String appBarTitle;
  final String headline;
  final String description;
  final Object error;
  final StackTrace? stackTrace;
  final IconData icon;
  final List<Widget>? actions;
  final List<Widget>? extra;

  const ExceptionErrorPanel({
    super.key,
    required this.appBarTitle,
    required this.headline,
    required this.description,
    required this.error,
    this.stackTrace,
    this.icon = Icons.error_outline,
    this.actions,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: ErrorMessagePanel(
        icon: icon,
        title: headline,
        message: '$description\n\n$error',
        details: stackTrace?.toString(),
        actions: actions,
        extra: extra,
      ),
    );
  }
}
