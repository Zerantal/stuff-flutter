import 'dart:io';

import 'package:flutter/material.dart';

abstract class IImageDataService {
  /// Loads and returns an image widget based on a user-data image GUID.
  ///
  /// [imageGuid] is the unique identifier for the user's image.
  ///
  /// The service implementation will resolve this GUID to an actual image source
  /// (e.g., a local file path derived from the GUID, or a cloud storage URL).
  ///
  /// Returns a widget (typically an Image widget or a specific placeholder on error).
  Widget getUserImage(
    String imageGuid, {
    double? width,
    double? height,
    BoxFit? fit,
  });

  Future<String> saveUserImage(File imageFile); // Returns GUID
  Future<void> deleteUserImage(String imageGuid);
  Future<void> clearAllUserImages();
}

// New file:
// import 'dart:io';
//
// import '../core/helpers/image_ref.dart';
//
// abstract class IImageDataService {
//   /// Loads and returns a image reference on a data image GUID.
//   ///
//   /// [imageGuid] is the unique identifier for the user's image.
//   ///
//   /// The service implementation will resolve this GUID to an actual image source
//   /// (e.g., a local file path derived from the GUID, or a cloud storage URL).
//   ///
//   /// Returns an ImageRef, which a widget can then load.
//   ImageRef? getImage(String imageGuid);
//   Future<String> saveImage(File imageFile); // Returns image GUID
//   Future<void> deleteImage(String imageGuid);
//   Future<void> deleteAllImages();
// }