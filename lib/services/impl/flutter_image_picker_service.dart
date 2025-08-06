// lib/services/impl/flutter_image_picker_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

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
  final Uuid _uuid;

  FlutterImagePickerService({
    ImagePicker? imagePicker,
    IPermissionService? permissionService,
  }) : _imagePickerInstance = imagePicker ?? ImagePicker(),
       _permissionService = permissionService ?? PermissionHandlerService(),
       _uuid = const Uuid();

  /// --- Helper function to copy to a temporary file if needed ---
  Future<File> _ensureTemporaryCopy(XFile pickedFile) async {
    // Heuristic: On Windows, image_picker tends to return the original path.
    // On Android/iOS, it usually returns a path to a cached/temporary copy.
    // This could be made more robust if image_picker offered a flag or if
    // there was a more definitive way to check if the path is truly temporary.
    if (Platform.isWindows) {
      _logger.info(
        "Platform is Windows. Ensuring a temporary copy of the picked file: ${pickedFile.path}",
      );
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String fileExtension = p.extension(pickedFile.path);
        final String tempFileName = '${_uuid.v4()}$fileExtension';
        final String tempFilePath = p.join(tempDir.path, tempFileName);

        final File originalFile = File(pickedFile.path);
        final File tempCopiedFile = await originalFile.copy(tempFilePath);

        _logger.info(
          "Original file '${pickedFile.path}' copied to temporary service cache at '$tempFilePath'",
        );
        return tempCopiedFile; // Return the copy
      } catch (e, s) {
        _logger.severe(
          "Error creating temporary copy of picked file on Windows: $e",
          e,
          s,
        );
        // Fallback to returning the original file object if copy fails,
        // though this means the original might be deleted by mistake later.
        // Consider if rethrowing or returning null is better here.
        return File(pickedFile.path);
      }
    } else {
      // On other platforms (like Android/iOS), image_picker usually already provides a temp copy.
      _logger.finer(
        "Platform is not Windows. Assuming picked file is already a temporary copy: ${pickedFile.path}",
      );
      return File(pickedFile.path);
    }
  }

  @override
  Future<File?> pickImageFromCamera({
    double? maxWidth = kDefaultImageMaxWidth,
    double? maxHeight = kDefaultImageMaxHeight,
    int? imageQuality = kDefaultImageQuality,
  }) async {
    try {
      final bool hasPermission = await _permissionService
          .requestCameraPermission();
      if (!hasPermission) {
        _logger.warning("Camera permission denied.");
        // Consider returning null or a more specific error/result object
        // instead of throwing an Exception directly from the service.
        // For now, matching existing behavior.
        throw Exception("Camera permission denied.");
      }

      final XFile? pickedFile = await _imagePickerInstance.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        // For camera, the image is always new and stored in a temp location by image_picker.
        // So, direct conversion to File is usually safe here across platforms.
        // However, to be absolutely consistent and safe, especially if the behavior
        // of image_picker for camera on desktop ever changes, we could use _ensureTemporaryCopy.
        // For now, let's assume camera output is always temporary.
        _logger.info("Image picked from camera: ${pickedFile.path}");
        return File(pickedFile.path);
        // If you wanted to be hyper-cautious or if camera on desktop also saved to original location:
        // return await _ensureTemporaryCopy(pickedFile);
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

      final XFile? pickedFileByPlugin = await _imagePickerInstance.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFileByPlugin != null) {
        _logger.info(
          "Image picked from gallery by plugin: ${pickedFileByPlugin.path}",
        );
        // <<< USE THE HELPER TO ENSURE IT'S A TEMP COPY >>>
        return await _ensureTemporaryCopy(pickedFileByPlugin);
      }
      return null;
    } catch (e, s) {
      _logger.severe('Error picking image from gallery: $e', s);
      rethrow;
    }
  }
}
