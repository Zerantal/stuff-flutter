// lib/shared/image/src/image_file_provider_io.dart
// IO implementation (used on mobile/desktop)

import 'dart:io' show File;
import 'package:flutter/material.dart';

ImageProvider fileImage(String path, {double scale = 1.0}) {
  return FileImage(File(path), scale: scale);
}
