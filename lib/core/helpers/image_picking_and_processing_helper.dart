// lib/core/helpers/image_picking_and_processing_helper.dart
import 'dart:io';
import 'package:logging/logging.dart';

import '../image_identifier.dart';
import '../image_source_type_enum.dart';
import '../../services/image_picker_service_interface.dart';
import '../../services/image_data_service_interface.dart';
import '../../services/temporary_file_service_interface.dart';

class ImagePickingAndProcessingHelper {
  final IImagePickerService _imagePickerService;
  final IImageDataService? _imageDataService; // Can be null
  final ITemporaryFileService _tempFileService;
  final Logger _logger;

  ImagePickingAndProcessingHelper({
    required IImagePickerService imagePickerService,
    required IImageDataService? imageDataService,
    required ITemporaryFileService tempFileService,
    required Logger logger,
  }) : _imagePickerService = imagePickerService,
       _imageDataService = imageDataService,
       _tempFileService = tempFileService,
       _logger = logger;

  /// Picks an image from the specified [source].
  ///
  /// If [directSaveWithImageDataService] is true and [_imageDataService] is available,
  /// the image will be saved directly, and a [GuidIdentifier] will be returned.
  /// The original picked file from the image_picker cache will be deleted.
  ///
  /// If [directSaveWithImageDataService] is false or [_imageDataService] is null,
  /// the image will be copied to the [sessionTempDir], and a [TempFileIdentifier]
  /// will be returned. The original picked file will also be deleted after copying.
  ///
  /// [sessionTempDir] must be provided if [directSaveWithImageDataService] is false
  /// or [_imageDataService] is null.
  ///
  /// Returns an [ImageIdentifier] (either [GuidIdentifier] or [TempFileIdentifier])
  /// if successful, or null if picking was cancelled or failed.
  Future<ImageIdentifier?> pickImage({
    required ImageSourceType source,
    required bool directSaveWithImageDataService,
    Directory? sessionTempDir, // Required if not direct saving
  }) async {
    _logger.info(
      "Helper: Attempting to pick image from $source. Direct save: $directSaveWithImageDataService",
    );

    // Determine if we will attempt a direct save or need to copy to temp.
    bool willAttemptDirectSave =
        directSaveWithImageDataService && _imageDataService != null;

    if (!willAttemptDirectSave) {
      // If not attempting direct save (either by choice or because service is null),
      // sessionTempDir is absolutely required.
      if (directSaveWithImageDataService && _imageDataService == null) {
        _logger.warning(
          "Helper: directSaveWithImageDataService is true, but ImageDataService is null. Fallback to temp copy.",
        );
      }
      if (sessionTempDir == null) {
        _logger.severe(
          "Helper: sessionTempDir must be provided if not performing a direct save or if ImageDataService is null (fallback).",
        );
        throw ArgumentError(
          "sessionTempDir must be provided when not performing a direct save or if ImageDataService is null (triggering fallback to temp copy).",
        );
      }
    }

    File? pickedFileFromPicker;
    try {
      if (source == ImageSourceType.camera) {
        pickedFileFromPicker = await _imagePickerService.pickImageFromCamera();
      } else {
        pickedFileFromPicker = await _imagePickerService.pickImageFromGallery();
      }

      if (pickedFileFromPicker == null) {
        _logger.info(
          "Helper: Image picking cancelled or failed (null file returned from picker).",
        );
        return null;
      }
      _logger.finer("Helper: Image picked: ${pickedFileFromPicker.path}");

      if (willAttemptDirectSave) {
        // _imageDataService is guaranteed to be non-null here due to 'willAttemptDirectSave' logic
        _logger.finer("Helper: Saving directly via ImageDataService...");
        final String imageGuid = await _imageDataService.saveUserImage(
          pickedFileFromPicker,
        );
        _logger.info("Helper: Image saved with GUID: $imageGuid.");
        try {
          await pickedFileFromPicker.delete();
          _logger.finer(
            "Helper: Deleted picker's temp file: ${pickedFileFromPicker.path}",
          );
        } catch (e) {
          _logger.warning(
            "Helper: Failed to delete picker's temp file ${pickedFileFromPicker.path} after direct save: $e",
          );
        }
        return GuidIdentifier(imageGuid);
      } else {
        // If we reach here, we are NOT doing a direct save.
        // And due to the upfront validation, sessionTempDir is GUARANTEED to be non-null.
        // Therefore, the `if (sessionTempDir == null)` check that threw a StateError is no longer needed.
        _logger.finer(
          "Helper: Copying to session temp dir: ${sessionTempDir!.path}",
        ); // Note: Can use ! due to earlier check
        final File tempCopiedFile = await _tempFileService.copyToTempDir(
          pickedFileFromPicker,
          sessionTempDir,
        );
        _logger.info(
          "Helper: Image copied to session temp: ${tempCopiedFile.path}",
        );
        try {
          await pickedFileFromPicker.delete();
          _logger.finer(
            "Helper: Deleted picker's temp file: ${pickedFileFromPicker.path} after copying to session.",
          );
        } catch (e) {
          _logger.warning(
            "Helper: Failed to delete picker's temp file ${pickedFileFromPicker.path} after copying to session: $e",
          );
        }
        return TempFileIdentifier(tempCopiedFile);
      }
    } catch (e, s) {
      _logger.severe('Helper: Error during pickImage: $e', e, s);
      if (pickedFileFromPicker != null && await pickedFileFromPicker.exists()) {
        try {
          await pickedFileFromPicker.delete();
          _logger.info(
            "Helper: Cleaned up picker's temp file after error: ${pickedFileFromPicker.path}",
          );
        } catch (deleteError) {
          _logger.warning(
            "Helper: Failed to cleanup picker's temp file ${pickedFileFromPicker.path} after an error: $deleteError",
          );
        }
      }
      return null;
    }
  }
}
