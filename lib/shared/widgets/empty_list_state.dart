import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (onAdd != null && buttonText != null)
              ElevatedButton.icon(icon: buttonIcon, label: Text(buttonText!), onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
