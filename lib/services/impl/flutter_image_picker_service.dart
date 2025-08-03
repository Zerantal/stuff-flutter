// lib/services/impl/flutter_image_picker_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

import '../image_picker_service_interface.dart';
import '../permission_service_interface.dart';
import 'permission_handler_service.dart';

final Logger _logger = Logger('FlutterImagePickerService');

const double kDefaultImageMaxWidth = 1920.0;
const double kDefaultImageMaxHeight = 1200.0;
const int kDefaultImageQuality = 85;

class FlutterImagePickerService implements IImagePickerService {
  final ImagePicker _imagePickerInstance;
  final IPermissionService _permissionService;

  FlutterImagePickerService({
    ImagePicker? imagePicker,
    IPermissionService? permissionService,
  }) : _imagePickerInstance = imagePicker ?? ImagePicker(),
       _permissionService =
           permissionService ??
           PermissionHandlerService(); // Default real implementation

  @override
  Future<File?> pickImageFromCamera({
    double? maxWidth = kDefaultImageMaxWidth, // Default sensible values
    double? maxHeight = kDefaultImageMaxHeight,
    int? imageQuality = kDefaultImageQuality,
  }) async {
    try {
      final bool hasPermission = await _permissionService
          .requestCameraPermission();
      if (!hasPermission) {
        _logger.warning("Camera permission denied.");
        throw Exception("Camera permission denied.");
      }

      final XFile? pickedFile = await _imagePickerInstance.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e, s) {
      _logger.severe('Error picking image from camera: $e', s);
      rethrow;
    }
  }

  @override
  Future<File?> pickImageFromGallery({
    double? maxWidth = kDefaultImageMaxWidth,
    double? maxHeight = kDefaultImageMaxHeight,
    int? imageQuality = kDefaultImageQuality,
  }) async {
    try {
      final bool hasPermission = await _permissionService
          .requestGalleryPermission();
      if (!hasPermission) {
        _logger.warning("Gallery permission denied.");
        throw Exception("Gallery permission denied.");
      }

      final XFile? pickedFile = await _imagePickerInstance.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e, s) {
      _logger.severe('Error picking image from gallery: $e', s);
      rethrow;
    }
  }
}
