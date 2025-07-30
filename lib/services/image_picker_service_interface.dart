// lib/services/image_picker_service_interface.dart
import 'dart:io';

abstract class IImagePickerService {
  Future<File?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  });

  Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  });
}
