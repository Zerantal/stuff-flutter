// lib/shared/forms/decoration.dart
import 'package:flutter/material.dart';

InputDecoration entityDecoration({required String label, String? hint}) =>
    InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder());
