// viewmodels/mixins/has_image_picking.dart
//
// Reusable mixin any VM can adopt to pick images and expose refs cleanly.

import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../image/image_picker_controller.dart';
import '../../image/pick_result.dart';

mixin HasImagePicking on ChangeNotifier {
  /// Must be assigned by the VM's constructor.
  late ImagePickerController imagePicker;

  // Shared state
  bool _isPickingImage = false;
  bool get isPickingImage => _isPickingImage;

  Future<PickResult> pickFromGallery() async {
    return _do(() => imagePicker.pickFromGallery());
  }

  Future<PickResult> pickFromCamera() async {
    return _do(() => imagePicker.pickFromCamera());
  }

  Future<PickResult> pickFromGalleryAndPersist() async {
    return _do(() => imagePicker.pickFromGalleryAndPersist());
  }

  Future<PickResult> pickFromCameraAndPersist() async {
    return _do(() => imagePicker.pickFromCameraAndPersist());
  }

  Future<PickResult> persistTemp(File file) async {
    return _do(() => imagePicker.persistTemp(file));
  }

  Future<PickResult> _do(Future<PickResult> Function() op) async {
    if (isPickingImage) return PickFailed(StateError('Busy'));
    _isPickingImage = true;
    notifyListeners();
    try {
      final result = await op();
      return result;
    } finally {
      _isPickingImage = false;
      notifyListeners();
    }
  }
}
