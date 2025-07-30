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
import '../models/location_model.dart';
import '../core/image_identifier.dart';

final Logger _logger = Logger('EditLocationViewModel');

class EditLocationViewModel extends ChangeNotifier {
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
  }) : _dataService = dataService,
       _imageDataService = imageDataService,
       _locationService = locationService,
       _imagePickerService = imagePickerService,
       _tempFileService = tempFileService,
       _initialLocation = initialLocation {
    _initialize();
  }

  // --- State Variables ---
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController addressController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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

  bool _isSaving = false;
  bool get isSaving => _isSaving;

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
    checkLocationServiceStatus();
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
    notifyListeners();

    try {
      String? address = await _locationService.getCurrentAddress();
      if (address != null) {
        addressController.text = address;
      }
    } catch (e) {
      _logger.severe("Error getting current address: $e");
      await checkLocationServiceStatus();
    } finally {
      _isGettingLocation = false;
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    if (_tempDir == null) {
      _logger.warning(
        "Temporary directory not initialized. Cannot pick image.",
      );
      return;
    }

    try {
      _logger.info("Attempting to pick image from camera...");
      final File? pickedImageFile = await _imagePickerService
          .pickImageFromCamera(
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
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
    if (!(formKey.currentState?.validate() ?? false)) {
      _logger.info("Save attempt failed: Form validation errors.");
      return false;
    }
    formKey.currentState!.save();
    return true;
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
      final Set<String> finalGuidsSet = Set.from(finalImageGuidsForLocation);
      List<String> guidsToDeletePermanently = initialImageGuids
          .where((initialGuid) => !finalGuidsSet.contains(initialGuid))
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
      _logger.info(
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
    if (!_validateForm()) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final List<String> finalImageGuids = await _processImagesForSave(
        _currentImages,
        _initialPersistedGuids,
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

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    // Important: Cleanup should ideally be tied to view model lifecycle if it's
    // scoped to the page. If it's a shared ViewModel, be careful.
    // If using WillPopScope and custom back button in UI to call handleDiscardOrPop,
    // this explicit call here might be redundant or for safety.
    // Consider if _locationSuccessfullySaved is still needed or if logic flows ensure cleanup.
    if (!_isSaving) {
      // Or a more robust check if it was not saved
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _cleanupTempDir();
      });
    }
    super.dispose();
  }
}
