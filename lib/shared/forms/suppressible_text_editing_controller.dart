// lib/shared/forms/suppressible_text_editing_controller.dart
import 'package:flutter/material.dart';

class SuppressibleTextEditingController {
  final TextEditingController controller;
  bool _suppress = false;

  SuppressibleTextEditingController({String? text})
    : controller = TextEditingController(text: text);

  void silentUpdate(String text) => silentEdit((c) => c.text = text);

  /// Batch edits (text, selection, composing) without notifying listeners.
  void silentEdit(void Function(TextEditingController c) fn) {
    _suppress = true;
    fn(controller);
    _suppress = false;
  }

  void addListener(VoidCallback listener) {
    controller.addListener(() {
      if (!_suppress) listener();
    });
  }

  void dispose() => controller.dispose();

  // Forwards
  String get text => controller.text;
  set text(String v) => controller.text = v; // normal (not silent)
  TextSelection get selection => controller.selection;
  set selection(TextSelection s) => controller.selection = s;

  TextEditingController get raw => controller;
}
