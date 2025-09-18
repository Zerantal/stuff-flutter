import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class EmptyListState extends StatelessWidget {
  const EmptyListState({
    super.key,
    this.onAdd,
    required this.text,
    this.buttonText,
    this.buttonIcon,
  });
  final VoidCallback? onAdd;
  final String text;
  final String? buttonText;
  final Icon? buttonIcon;

  @override
  Widget build(BuildContext context) {
    assert(
      !((onAdd == null) ^ (buttonText == null)),
      'Must provide onAdd and buttonText, or neither',
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            if (onAdd != null && buttonText != null)
              ElevatedButton.icon(icon: buttonIcon, label: Text(buttonText!), onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
