// lib/shared/forms/suppressible_text_editing_controller.dart
import 'package:flutter/material.dart';

class SuppressibleTextEditingController {
  final TextEditingController controller;
  bool _suppress = false;

  // keep track of wrapped closures so we can remove them later
  final List<VoidCallback> _wrappedListeners = [];

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
    void wrapped() {
      if (!_suppress) listener();
    }

    _wrappedListeners.add(wrapped);
    controller.addListener(wrapped);
  }

  void clearListeners() {
    for (final wrapped in _wrappedListeners) {
      controller.removeListener(wrapped);
    }
    _wrappedListeners.clear();
  }

  void dispose() {
    clearListeners();
    controller.dispose();
  }

  // Forwards
  String get text => controller.text;
  set text(String v) => controller.text = v; // normal (not silent)
  TextSelection get selection => controller.selection;
  set selection(TextSelection s) => controller.selection = s;

  TextEditingController get raw => controller;
}
