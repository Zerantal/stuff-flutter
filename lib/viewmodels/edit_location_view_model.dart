// lib/viewmodels/edit_location_view_model.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../services/data_service_interface.dart';
import '../services/image_data_service_interface.dart';
import '../services/location_service_interface.dart';
import '../services/image_picker_service_interface.dart';
import '../services/temporary_file_service_interface.dart';
import '../services/exceptions/permission_exceptions.dart';
import '../services/exceptions/os_service_exceptions.dart';
import '../models/location_model.dart';
import '../core/image_identifier.dart';

final Logger _logger = Logger('EditLocationViewModel');

enum ImageSourceType { camera, gallery }

typedef FormValidationCallback = bool Function();

class EditLocationViewModel extends ChangeNotifier {
  late FormValidationCallback _validateFormCallback;
  final IDataService _dataService;
  final IImageDataService? _imageDataService;
  final ILocationService _locationService;
  final IImagePickerService _imagePickerService;
  final ITemporaryFileService _tempFileService;
  final Location? _initialLocation;

  EditLocationViewModel({
    required IDataService dataService,
    required IImageDataService? imageDataService,
    required ILocationService locationService,
    required IImagePickerService imagePickerService,
    required ITemporaryFileService tempFileService,
    Location? initialLocation,
    FormValidationCallback? formValidator,
  }) : _dataService = dataService,
       _imageDataService = imageDataService,
       _locationService = locationService,
       _imagePickerService = imagePickerService,
       _tempFileService = tempFileService,
       _initialLocation = initialLocation {
    _validateFormCallback =
        formValidator ?? (() => _formKey.currentState?.validate() ?? false);
    _initialize();
  }

  // --- State Variables ---
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController addressController;

  List<ImageIdentifier> _currentImages = [];
  List<ImageIdentifier> get currentImages => List.unmodifiable(_currentImages);

  List<String> _initialPersistedGuids = [];

  bool _isNewLocation = true;
  bool get isNewLocation => _isNewLocation;

  bool _isGettingLocation = false;
  bool get isGettingLocation => _isGettingLocation;

  Directory? _tempDir; // Will be managed by _tempFileService

  bool _deviceHasLocationService = true;
  bool get deviceHasLocationService => _deviceHasLocationService;

  // true if request for permission has been attempted but denied
  bool _locationPermissionDenied = false;
  bool get locationPermissionDenied => _locationPermissionDenied;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  // --- Initialization ---
  void _initialize() {
    _isNewLocation = _initialLocation == null;
    nameController = TextEditingController(text: _initialLocation?.name ?? '');
    descriptionController = TextEditingController(
      text: _initialLocation?.description ?? '',
    );
    addressController = TextEditingController(
      text: _initialLocation?.address ?? '',
    );

    if (_initialLocation?.imageGuids != null) {
      _initialPersistedGuids = List.from(_initialLocation!.imageGuids!);

      _currentImages = _initialPersistedGuids
          .map<ImageIdentifier>((guid) => GuidIdentifier(guid))
          .toList();
    }
    _initializeTempDirectory();
  }

  Future<void> refreshLocationServiceStatus() async {
    bool previousStatus = _deviceHasLocationService;
    _deviceHasLocationService = await _locationService
        .isServiceEnabledAndPermitted();
    if (previousStatus != _deviceHasLocationService) {
      _locationPermissionDenied = !_deviceHasLocationService;
      notifyListeners();
    }
  }

  Future<void> _initializeTempDirectory() async {
    try {
      _tempDir = await _tempFileService.createSessionTempDir(
        'edit_location_session',
      );
      _logger.info(
        "Temporary image directory for this session: ${_tempDir?.path}",
      );
    } catch (e, s) {
      _logger.severe("Failed to initialize temporary image directory: $e", s);
    }
  }

  Future<void> checkLocationServiceStatus() async {
    bool previousStatus = _deviceHasLocationService;
    _deviceHasLocationService = await _locationService
        .isServiceEnabledAndPermitted();
    if (previousStatus != _deviceHasLocationService) {
      notifyListeners();
    }
  }

  Future<void> getCurrentAddress() async {
    if (_isGettingLocation) return;
    _isGettingLocation = true;
    _locationPermissionDenied = false;
    _deviceHasLocationService = true; // Assume true until a problem is found
    notifyListeners();

    try {
      String? address = await _locationService.getCurrentAddress();
      if (address != null) {
        addressController.text = address;
        _deviceHasLocationService = true;
      } else {
        _logger.warning("getCurrentAddress returned null but no exception.");
      }
    } on LocationPermissionDeniedException catch (e) {
      // Custom exception from your ILocationService
      _logger.warning("Location permission denied: $e");
      _deviceHasLocationService = false;
      _locationPermissionDenied = true;
    } on PermissionDeniedPermanentlyException catch (e) {
      // Custom exception
      _logger.warning("Location permission permanently denied: $e");
      _deviceHasLocationService = false;
      _locationPermissionDenied = true;
      // Optionally, set another flag to prompt user to go to settings
      // e.g., _shouldShowOpenSettingsPrompt = true;
    } on OSServiceDisabledException catch (e) {
      // Custom exception
      _logger.warning("Location service disabled: $e");
      _deviceHasLocationService = false;
      _locationPermissionDenied =
          true; // Treat as a permission issue for UI message
    } catch (e, s) {
      _logger.severe("Error getting current address: $e", s);
      _deviceHasLocationService =
          false; // A generic error also means service isn't working as expected
      _locationPermissionDenied =
          true; // Show the error message for any failure
    } finally {
      _isGettingLocation = false;
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    await _pickImage(ImageSourceType.camera);
  }

  Future<void> pickImageFromGallery() async {
    await _pickImage(ImageSourceType.gallery);
  }

  Future<void> _pickImage(ImageSourceType source) async {
    if (_tempDir == null) {
      _logger.warning(
        "Temporary directory not initialized. Cannot pick image.",
      );
      return;
    }

    try {
      _logger.info("Attempting to pick image from camera...");
      final File? pickedImageFile = source == ImageSourceType.camera
          ? await _imagePickerService.pickImageFromCamera()
          : await _imagePickerService.pickImageFromGallery();

      _logger.info(
        "Returned from image picker. Picked file: ${pickedImageFile?.path}",
      );

      if (pickedImageFile != null) {
        final File tempCopiedFile = await _tempFileService.copyToTempDir(
          pickedImageFile,
          _tempDir!,
        );
        _currentImages.add(TempFileIdentifier(tempCopiedFile));
        _logger.info(
          "New image picked and copied to temporary location: ${tempCopiedFile.path}",
        );
        notifyListeners();
      }
    } catch (e, s) {
      _logger.severe("Error picking/copying image to temp: $e", s);
    }
  }

  Future<void> removeImage(int index) async {
    if (index < 0 || index >= _currentImages.length) return;

    final imageIdToRemove = _currentImages.removeAt(index);

    notifyListeners();

    if (imageIdToRemove is TempFileIdentifier) {
      try {
        await _tempFileService.deleteFile(imageIdToRemove.file);
        _logger.info(
          "Temporary image file deleted: ${imageIdToRemove.file.path}",
        );
      } catch (e, s) {
        _logger.warning(
          "Failed to delete temporary image file ${imageIdToRemove.file.path}: $e",
          s,
        );
      }
    } else if (imageIdToRemove is GuidIdentifier) {
      _logger.info(
        "Image with GUID ${imageIdToRemove.guid} marked for removal from location's list.",
      );
      // Actual deletion from storage will happen during saveLocation
    }
  }

  bool _validateForm() {
    return _validateFormCallback();
  }

  Future<List<String>> _processImagesForSave(
    List<ImageIdentifier> currentImageIdentifiers,
    List<String> initialImageGuids,
  ) async {
    List<String> finalImageGuidsForLocation = [];

    if (_imageDataService != null) {
      final imageService = _imageDataService;

      // 1. Save new temporary images
      for (var identifier in currentImageIdentifiers) {
        if (identifier is TempFileIdentifier) {
          try {
            final String savedGuid = await imageService.saveUserImage(
              identifier.file,
            );
            finalImageGuidsForLocation.add(savedGuid);
            _logger.info(
              "Saved temp image ${identifier.file.path} as GUID: $savedGuid",
            );
          } catch (e, s) {
            _logger.severe(
              "Failed to save image ${identifier.file.path}: $e",
              s,
            );
            throw Exception("Failed to save image ${identifier.file.path}: $e");
          }
        } else if (identifier is GuidIdentifier) {
          finalImageGuidsForLocation.add(identifier.guid);
        }
      }

      // 2. Delete images that were removed from the list
      Set<String> currentPersistedGuids = currentImageIdentifiers
          .whereType<GuidIdentifier>()
          .map((gi) => gi.guid)
          .toSet();
      List<String> guidsToDeletePermanently = _initialPersistedGuids
          .where((initialGuid) => !currentPersistedGuids.contains(initialGuid))
          .toList();

      for (String guidToDelete in guidsToDeletePermanently) {
        try {
          _logger.info(
            "Permanently deleting image GUID: $guidToDelete as it was removed from location.",
          );
          await imageService.deleteUserImage(guidToDelete);
        } catch (e, s) {
          _logger.severe("Failed to delete image GUID $guidToDelete: $e", s);
          throw Exception("Failed to delete image GUID $guidToDelete: $e");
        }
      }
    } else {
      // ImageDataService is null
      if (currentImageIdentifiers.any((img) => img is TempFileIdentifier)) {
        _logger.severe(
          "Cannot save new images: IImageDataService is not available.",
        );
        for (var identifier in currentImageIdentifiers) {
          if (identifier is TempFileIdentifier) {
            try {
              await _tempFileService.deleteFile(identifier.file);
              _logger.info(
                "Cleaned up unsaved temp image: ${identifier.file.path}",
              );
            } catch (e) {
              _logger.warning(
                "Failed to cleanup unsaved temp image ${identifier.file.path}: $e",
              );
            }
          }
        }
        throw Exception(
          "Cannot save new images as the image service is unavailable.",
        );
      }
      _logger.warning(
        "IImageDataService is null. Proceeding without image saving/deletion capabilities.",
      );
      finalImageGuidsForLocation = currentImageIdentifiers
          .whereType<GuidIdentifier>()
          .map((gi) => gi.guid)
          .toList();
    }
    return finalImageGuidsForLocation;
  }

  Future<void> _saveLocationData(Location locationToSave) async {
    if (_isNewLocation) {
      await _dataService.addLocation(locationToSave);
      _logger.info("New location added successfully: ${locationToSave.id}");
    } else {
      await _dataService.updateLocation(locationToSave);
      _logger.info("Location updated successfully: ${locationToSave.id}");
    }
  }

  Future<bool> saveLocation() async {
    if (_isSaving) return false;
    if (!_validateForm()) {
      _logger.warning("Validation failed. Cannot save location.");
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final List<String> finalImageGuids = await _processImagesForSave(
        List.from(_currentImages),
        List.from(_initialPersistedGuids),
      );

      final locationToSave = Location(
        id: _initialLocation?.id ?? const Uuid().v4(),
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        imageGuids: finalImageGuids.isEmpty ? null : finalImageGuids,
      );

      await _saveLocationData(locationToSave);

      await _cleanupTempDir();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e, s) {
      _logger.severe("Error saving location or processing images: $e", s);
      await _cleanupTempDir();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Widget getImageThumbnailWidget(
    ImageIdentifier identifier, {
    required double width,
    required double height,
    required BoxFit fit,
  }) {
    if (identifier is GuidIdentifier) {
      if (_imageDataService == null) {
        _logger.warning(
          "IImageDataService is null in ViewModel, cannot display persisted image for GUID: ${identifier.guid}",
        );
        return SizedBox(
          // Return a SizedBox or a more specific placeholder
          width: width,
          height: height,
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 50),
          ),
        );
      }

      return _imageDataService.getUserImage(
        identifier.guid,
        width: width,
        height: height,
        fit: fit,
      );
    } else if (identifier is TempFileIdentifier) {
      return Image.file(
        identifier.file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          _logger.severe(
            "Error loading TEMP image ${identifier.file.path} in ViewModel: $error",
            error,
            stackTrace,
          );
          return SizedBox(
            // Return a SizedBox or a more specific placeholder
            width: width,
            height: height,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
            ),
          );
        },
      );
    }
    // Fallback for unknown types, though ideally your ImageIdentifier hierarchy is sealed/exhaustive
    _logger.warning(
      "Unknown ImageIdentifier type encountered in ViewModel.getImageThumbnailWidget: ${identifier.runtimeType}",
    );
    return SizedBox(
      width: width,
      height: height,
      child: const Center(child: Icon(Icons.help_outline)),
    );
  }

  Future<void> handleDiscardOrPop() async {
    _logger.info("Handling discard or pop. Cleaning up session resources.");
    await _cleanupTempDir();
  }

  Future<void> _cleanupTempDir() async {
    if (_tempDir != null && await _tempDir!.exists()) {
      try {
        await _tempFileService.deleteDirectory(_tempDir!);
        _logger.info("Cleaned up temporary image directory: ${_tempDir!.path}");
        _tempDir = null;
      } catch (e, s) {
        _logger.warning(
          "Failed to clean up temporary image directory ${_tempDir!.path}: $e",
          s,
        );
      }
    }
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    if (_isDisposed) return;

    _logger.finer("Disposing EditLocationViewModel.");
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();

    if (_tempDir != null) {
      _logger.warning(
        "ViewModel disposed, but temp directory was not cleaned up. Attempting cleanup now. This might indicate an unhandled exit path.",
      );

      _cleanupTempDir().catchError((e, s) {
        _logger.severe("Error during fallback cleanup in dispose: $e", s);
      });
    }

    _isDisposed = true;
    super.dispose();
  }
}
