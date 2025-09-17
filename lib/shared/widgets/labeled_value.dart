// lib/shared/widgets/labeled_value.dart
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Displays a label (e.g. "Name") and its corresponding value.
/// Useful for view-only pages (item details, location details).
class LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final bool dense;

  const LabeledValue(this.label, this.value, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? AppSpacing.xs : AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
