// lib/core/helpers/src/image_file_provider_stub.dart
// Web-safe stub (used when dart:io is unavailable)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

ImageProvider fileImage(String path, {double scale = 1.0}) {
  if (kIsWeb) {
    throw UnsupportedError('ImageRef.file is not supported on web.');
  }
  // Fallback for non-IO platforms where FileImage is unavailable.
  throw UnsupportedError('File images not supported on this platform.');
}
