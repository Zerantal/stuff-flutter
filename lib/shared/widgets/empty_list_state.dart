import 'package:flutter/material.dart';

class EmptyListState extends StatelessWidget {
  const EmptyListState({
    super.key,
    required this.onAdd,
    required this.text,
    required this.buttonText,
    this.buttonIcon,
  });
  final VoidCallback onAdd;
  final String text;
  final String buttonText;
  final Icon? buttonIcon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(icon: buttonIcon!, label: Text(buttonText), onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
