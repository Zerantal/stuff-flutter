// lib/services/impl/flutter_image_picker_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

import '../contracts/image_picker_service_interface.dart';
import '../contracts/permission_service_interface.dart';
import 'permission_handler_service.dart';

final Logger _logger = Logger('FlutterImagePickerService');

const double kDefaultImageMaxWidth = 1920.0;
const double kDefaultImageMaxHeight = 1200.0;
const int kDefaultImageQuality = 85;

class FlutterImagePickerService implements IImagePickerService {
  final ImagePicker _picker;

  final IPermissionService _perm;

  FlutterImagePickerService({ImagePicker? imagePicker, IPermissionService? permissionService})
    : _picker = imagePicker ?? ImagePicker(),
      _perm = permissionService ?? PermissionHandlerService();

  @override
  Future<File?> pickImageFromCamera({
    double? maxWidth = kDefaultImageMaxWidth,
    double? maxHeight = kDefaultImageMaxHeight,
    int? imageQuality = kDefaultImageQuality,
  }) {
    return _pick(
      ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      requestPermission: _perm.requestCameraPermission,
    );
  }

  @override
  Future<File?> pickImageFromGallery({
    double? maxWidth = kDefaultImageMaxWidth,
    double? maxHeight = kDefaultImageMaxHeight,
    int? imageQuality = kDefaultImageQuality,
  }) {
    return _pick(
      ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      requestPermission: _perm.requestGalleryPermission,
    );
  }

  Future<File?> _pick(
    ImageSource source, {
    required Future<bool> Function() requestPermission,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final ok = await requestPermission();
      if (!ok) {
        _logger.warning('Permission denied for $source');
        return null;
      }

      final XFile? xf = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      if (xf == null) {
        _logger.finer('User cancelled $source pick');
        return null;
      }

      _logger.info('Picked image ($source): ${xf.path}');
      return File(xf.path);
    } catch (e, s) {
      _logger.severe('Error picking image from $source', e, s);
      // Let the caller decide whether to surface as an error state.
      rethrow;
    }
  }
}
