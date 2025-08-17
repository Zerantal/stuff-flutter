import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MobileSaver {
  static const _channel = MethodChannel('com.example.stuff/media');

  /// Saves [bytes] as [fileName] into user's Photos/Gallery on Android.
  /// Returns:
  /// - true if saved,
  /// - false if not supported on this platform or failed.
  static Future<bool> saveToGallery(
    Uint8List bytes, {
    required String fileName,
    String album = 'Stuff',
  }) async {
    if (kIsWeb || !(Platform.isAndroid)) {
      return false; // iOS not implemented here; returns false (falls back to share)
    }
    try {
      final ok = await _channel.invokeMethod<bool>('saveImage', {
        'bytes': bytes,
        'name': fileName,
        'album': album,
      });
      return ok == true;
    } on PlatformException {
      return false;
    }
  }
}
