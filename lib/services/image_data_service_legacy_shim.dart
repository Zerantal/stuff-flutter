// lib/services/image_data_service_legacy_shim.dart
//
// Temporary compatibility layer so existing ViewModels keep working while you refactor.
// Remove after migrating VMs to use getImage(...) + buildImage(...) in the View.

import 'dart:io';
import 'package:flutter/material.dart';

import '../core/helpers/image_ref.dart';
import 'image_data_service_interface.dart';

extension LegacyImageDataService on IImageDataService {
  /// Old name → new API
  Future<String> saveUserImage(File imageFile) => saveImage(imageFile);

  /// Old name → new API
  Future<void> deleteUserImage(String imageGuid) => deleteImage(imageGuid);

  /// Old API returned a Widget. We emulate that using FutureBuilder + your ImageRef -> Image helper.
  ///
  /// Note: This keeps UI concerns inside a *temporary shim*, not your VM class.
  /// Once refactoring is done, delete this and build the image widget in the Page.
  Widget getUserImage(
    String imageGuid, {
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
    Widget? placeholder,
    Widget? errorWidget,
    bool verifyExists = true,
  }) {
    return FutureBuilder<ImageRef?>(
      future: getImage(imageGuid, verifyExists: verifyExists),
      builder: (context, snapshot) {
        // still loading → show placeholder if provided
        if (snapshot.connectionState != ConnectionState.done) {
          return placeholder ??
              const SizedBox(
                width: 20,
                height: 20,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
        }

        final ref = snapshot.data;
        if (ref == null) {
          // not found / missing → show error widget or a tiny fallback
          return errorWidget ??
              const Center(child: Icon(Icons.broken_image_outlined, size: 20));
        }

        // Use your existing helper to build an Image from ImageRef.
        return buildImage(
          ref,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          filterQuality: filterQuality,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          loadingWidget: placeholder,
          errorWidget: errorWidget,
        );
      },
    );
  }
}
