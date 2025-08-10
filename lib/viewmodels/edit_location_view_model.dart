// lib/viewmodels/edit_location_view_model.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../core/helpers/image_ref.dart';
import '../image/image_picker_controller.dart';
import '../models/location_model.dart';
import '../services/data_service_interface.dart';
import '../services/image_data_service_interface.dart';
import '../services/image_picker_service_interface.dart';
import '../services/location_service_interface.dart';
import '../services/temporary_file_service_interface.dart';
import 'state/edit_location_state.dart';
import 'mixins/has_image_picking.dart';

class EditLocationViewModel extends ChangeNotifier with HasImagePicking {
  final IDataService _dataService;
  final IImageDataService? _imageDataService;
  final ILocationService _locationService;
  final IImagePickerService _imagePickerService;
  final ITemporaryFileService _tempFileService;
  final Logger _logger = Logger('EditLocationVM');

  final Location? _initialLocation;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  EditLocationState _state = const EditLocationState(
    name: '',
    isNewLocation: true,
  );

  EditLocationState get state => _state;

  // Back-compat with your existing page API during refactor:
  bool get isNewLocation => _state.isNewLocation;
  bool get isSaving => _state.isSaving;
  bool get isGettingLocation => _state.isGettingLocation;
  bool get deviceHasLocationService => _state.deviceHasLocationService;
  bool get hasUnsavedChanges => _state.hasUnsavedChanges;
  List<ImageRef> get currentImages => _state.images;

  EditLocationViewModel({
    required IDataService dataService,
    required IImageDataService? imageDataService,
    required ILocationService locationService,
    required IImagePickerService imagePickerService,
    required ITemporaryFileService tempFileService,
    required Location? initialLocation,
  }) : _dataService = dataService,
       _imageDataService = imageDataService,
       _locationService = locationService,
       _imagePickerService = imagePickerService,
       _tempFileService = tempFileService,
       _initialLocation = initialLocation {
    if (_initialLocation != null) {
      nameController.text = _initialLocation.name;
      descriptionController.text = _initialLocation.description ?? '';
      addressController.text = _initialLocation.address ?? '';
      _state = _state.copyWith(
        name: _initialLocation.name,
        description: _initialLocation.description,
        address: _initialLocation.address,
        images: const [], // populate when you wire persistence
        isNewLocation: false,
      );
    }
    nameController.addListener(_onAnyFieldChanged);
    descriptionController.addListener(_onAnyFieldChanged);
    addressController.addListener(_onAnyFieldChanged);

    // wire mixin deps
    imagePicker = ImagePickerController(
      picker: imagePickerService,
      store: imageDataService,
      temp: tempFileService,
      logger: _logger,
    );
  }

  void _onAnyFieldChanged() {
    _state = _state.copyWith(
      name: nameController.text,
      description: descriptionController.text,
      address: addressController.text,
      hasUnsavedChanges: true,
    );
    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    if (_state.isPickingImage || _state.isSaving) return;
    _state = _state.copyWith(isPickingImage: true);
    notifyListeners();
    try {
      final File? picked = await _imagePickerService.pickImageFromCamera();
      if (picked == null) return;
      final next = List<ImageRef>.from(_state.images)
        ..add(ImageRef.file(picked.path));
      _state = _state.copyWith(images: next, hasUnsavedChanges: true);
    } catch (e, s) {
      _logger.severe('pickImageFromCamera failed', e, s);
    } finally {
      _state = _state.copyWith(isPickingImage: false);
      notifyListeners();
    }
  }

  Future<void> pickImageFromGallery() async {
    if (_state.isPickingImage || _state.isSaving) return;
    _state = _state.copyWith(isPickingImage: true);
    notifyListeners();
    try {
      final File? picked = await _imagePickerService.pickImageFromGallery();
      if (picked == null) return;
      final next = List<ImageRef>.from(_state.images)
        ..add(ImageRef.file(picked.path));
      _state = _state.copyWith(images: next, hasUnsavedChanges: true);
    } catch (e, s) {
      _logger.severe('pickImageFromGallery failed', e, s);
    } finally {
      _state = _state.copyWith(isPickingImage: false);
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index < 0 || index >= _state.images.length) return;
    final next = List<ImageRef>.from(_state.images)..removeAt(index);
    _state = _state.copyWith(images: next, hasUnsavedChanges: true);
    notifyListeners();
  }

  Future<void> getCurrentAddress() async {
    if (_state.isGettingLocation) return;
    _state = _state.copyWith(isGettingLocation: true);
    notifyListeners();
    try {
      // Replace with your real location-reverse-geocode workflow.
      // final addr = await _locationService.currentAddressLine();
      final addr = addressController.text; // placeholder
      addressController.text = addr;
      _state = _state.copyWith(address: addr, hasUnsavedChanges: true);
    } catch (e, s) {
      _logger.warning('getCurrentAddress failed', e, s);
    } finally {
      _state = _state.copyWith(isGettingLocation: false);
      notifyListeners();
    }
  }

  Future<bool> saveLocation() async {
    if (_state.isSaving) return false;
    _state = _state.copyWith(isSaving: true);
    notifyListeners();
    try {
      // TODO: persist via _dataService / _imageDataService.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _state = _state.copyWith(hasUnsavedChanges: false);
      return true;
    } catch (e, s) {
      _logger.severe('saveLocation failed', e, s);
      return false;
    } finally {
      _state = _state.copyWith(isSaving: false);
      notifyListeners();
    }
  }

  Future<void> handleDiscardOrPop(BuildContext context) async {
    if (!_state.hasUnsavedChanges) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Discard them and leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    super.dispose();
  }
}

// // lib/viewmodels/edit_location_view_model.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
// import 'package:uuid/uuid.dart';
//
// import '../services/data_service_interface.dart';
// import '../services/image_data_service_interface.dart';
// import '../services/location_service_interface.dart';
// import '../services/image_picker_service_interface.dart';
// import '../services/temporary_file_service_interface.dart';
// import '../services/exceptions/permission_exceptions.dart';
// import '../services/exceptions/os_service_exceptions.dart';
// import '../models/location_model.dart';
// import '../core/image_identifier.dart';
// import '../core/image_source_type_enum.dart';
// // import '../core/helpers/image_picking_and_processing_helper.dart';
// import '../core/helpers/image_ref.dart';
// import 'mixins/has_image_picking.dart';
// import '../core/helpers/image_identifier_to_ref.dart';
//
// // legacy support: will be removed soon
// import '../services/image_data_service_legacy_shim.dart';
//
//
// // final Logger _logger = Logger('EditLocationViewModel');
//
// typedef FormValidationCallback = bool Function();
//
// class EditLocationViewModel extends ChangeNotifier with HasImagePicking {
//   late FormValidationCallback _validateFormCallback;
//   final IDataService _dataService;
//   final IImageDataService? _imageDataService;
//   final ILocationService _locationService;
//   final IImagePickerService _imagePickerService;
//   final ITemporaryFileService _tempFileService;
//   final Location? _initialLocation;
//
//   // late ImagePickingAndProcessingHelper _imagePickingHelper;
//
//   // saved + non-saved images
//   late List<ImageIdentifier> _images = [];
//
//   EditLocationViewModel._({
//     required IDataService dataService,
//     required IImageDataService? imageDataService,
//     required ILocationService locationService,
//     required IImagePickerService imagePickerService,
//     required ITemporaryFileService tempFileService,
//     Location? initialLocation,
//     FormValidationCallback? formValidator,
//     required Logger logger,
//   }) : _dataService = dataService,
//        _imageDataService = imageDataService,
//        _locationService = locationService,
//        _imagePickerService = imagePickerService,
//        _tempFileService = tempFileService,
//        _initialLocation = initialLocation {
//     _validateFormCallback =
//         formValidator ?? (() => _formKey.currentState?.validate() ?? false);
//
//     // _imagePickingHelper = ImagePickingAndProcessingHelper(
//     //   imagePickerService: _imagePickerService,
//     //   imageDataService: _imageDataService,
//     //   tempFileService: _tempFileService,
//     //   logger: _logger,
//     // );
//
//     // wire mixin deps
//     this.imagePickerService = imagePickerService;
//     this.imageDataService   = imageDataService;
//     this.tempFileService    = tempFileService;
//     this.logger             = logger;
//
//     _initialize();
//   }
//
//   // --- State Variables ---
//   late TextEditingController nameController;
//   late TextEditingController descriptionController;
//   late TextEditingController addressController;
//
//   // saved + non-saved images
//   List<ImageRef> _currentImages = [];
//   List<ImageRef> get currentImages => List.unmodifiable(_currentImages);
//
//   // List<String> _savedImageGuids = [];
//
//   bool _isNewLocation = true;
//   bool get isNewLocation => _isNewLocation;
//
//   bool _isGettingLocation = false;
//   bool get isGettingLocation => _isGettingLocation;
//
//   Directory? _tempDir; // Will be managed by _tempFileService
//
//   bool _deviceHasLocationService = true;
//   bool get deviceHasLocationService => _deviceHasLocationService;
//
//   // true if request for permission has been attempted but denied
//   bool _locationPermissionDenied = false;
//   bool get locationPermissionDenied => _locationPermissionDenied;
//
//   bool _isSaving = false;
//   bool get isSaving => _isSaving;
//
//   bool _isPickingImage = false;
//   bool get isPickingImage => _isPickingImage;
//
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   GlobalKey<FormState> get formKey => _formKey;
//
//   // --- Initialization ---
//   void _initialize() {
//     _isNewLocation = _initialLocation == null;
//     nameController = TextEditingController(text: _initialLocation?.name ?? '');
//     descriptionController = TextEditingController(
//       text: _initialLocation?.description ?? '',
//     );
//     addressController = TextEditingController(
//       text: _initialLocation?.address ?? '',
//     );
//
//     if (_initialLocation?.images != null) {
//       _images = _initialLocation!.images.map<ImageIdentifier>(
//               (guid) => GuidIdentifier(guid)).toList();
//
//       _currentImages = await toImageRefs(_images);
//     }
//     _initializeTempDirectory();
//   }
//
//   Future<void> refreshLocationServiceStatus() async {
//     bool previousStatus = _deviceHasLocationService;
//     _deviceHasLocationService = await _locationService
//         .isServiceEnabledAndPermitted();
//     if (previousStatus != _deviceHasLocationService) {
//       _locationPermissionDenied = !_deviceHasLocationService;
//       notifyListeners();
//     }
//   }
//
//   Future<void> _initializeTempDirectory() async {
//     try {
//       _tempDir = await _tempFileService.createSessionTempDir(
//         'edit_location_session',
//       );
//       _logger.info(
//         "Temporary image directory for this session: ${_tempDir?.path}",
//       );
//     } catch (e, s) {
//       _logger.severe("Failed to initialize temporary image directory: $e", s);
//     }
//   }
//
//   Future<void> checkLocationServiceStatus() async {
//     bool previousStatus = _deviceHasLocationService;
//     _deviceHasLocationService = await _locationService
//         .isServiceEnabledAndPermitted();
//     if (previousStatus != _deviceHasLocationService) {
//       notifyListeners();
//     }
//   }
//
//   Future<void> getCurrentAddress() async {
//     if (_isGettingLocation) return;
//     _isGettingLocation = true;
//     _locationPermissionDenied = false;
//     _deviceHasLocationService = true; // Assume true until a problem is found
//     notifyListeners();
//
//     try {
//       String? address = await _locationService.getCurrentAddress();
//       if (address != null) {
//         addressController.text = address;
//         _deviceHasLocationService = true;
//       } else {
//         _logger.warning("getCurrentAddress returned null but no exception.");
//       }
//     } on LocationPermissionDeniedException catch (e) {
//       // Custom exception from your ILocationService
//       _logger.warning("Location permission denied: $e");
//       _deviceHasLocationService = false;
//       _locationPermissionDenied = true;
//     } on PermissionDeniedPermanentlyException catch (e) {
//       // Custom exception
//       _logger.warning("Location permission permanently denied: $e");
//       _deviceHasLocationService = false;
//       _locationPermissionDenied = true;
//       // Optionally, set another flag to prompt user to go to settings
//       // e.g., _shouldShowOpenSettingsPrompt = true;
//     } on OSServiceDisabledException catch (e) {
//       // Custom exception
//       _logger.warning("Location service disabled: $e");
//       _deviceHasLocationService = false;
//       _locationPermissionDenied =
//           true; // Treat as a permission issue for UI message
//     } catch (e, s) {
//       _logger.severe("Error getting current address: $e", s);
//       _deviceHasLocationService =
//           false; // A generic error also means service isn't working as expected
//       _locationPermissionDenied =
//           true; // Show the error message for any failure
//     } finally {
//       _isGettingLocation = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> pickImageFromCamera() async {
//     await _pickImageWithHelper(ImageSourceType.camera);
//   }
//
//   Future<void> pickImageFromGallery() async {
//     await _pickImageWithHelper(ImageSourceType.gallery);
//   }
//
//   Future<void> _pickImageWithHelper(ImageSourceType source) async {
//     if (_isPickingImage) return; // Prevent concurrent picks
//     _isPickingImage = true;
//     notifyListeners();
//
//     // For EditLocationViewModel, directSave is false because it collects all images
//     // and processes them (including new ones) during the main saveLocation() call.
//     // It uses its own _tempDir for images picked during the session.
//     bool directSave = false;
//
//     if (!directSave && _tempDir == null) {
//       _logger.warning(
//         "Temporary directory not initialized. Cannot pick image for non-direct save.",
//       );
//       _isPickingImage = false;
//       notifyListeners();
//       return;
//     }
//
//     try {
//       final ImageIdentifier? newImageId = await _imagePickingHelper.pickImage(
//         source: source,
//         directSaveWithImageDataService: directSave,
//         sessionTempDir: _tempDir,
//       );
//
//       if (newImageId != null) {
//         _currentImages.add(newImageId);
//         // notify in finally
//       }
//     } catch (e, s) {
//       _logger.severe(
//         "Error reported from ImagePickingHelper to ViewModel: $e",
//         s,
//       );
//     } finally {
//       _isPickingImage = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> removeImage(int index) async {
//     if (index < 0 || index >= _currentImages.length) return;
//
//     final imageIdToRemove = _currentImages.removeAt(index);
//
//     notifyListeners();
//
//     if (imageIdToRemove is TempFileIdentifier) {
//       try {
//         await _tempFileService.deleteFile(imageIdToRemove.file);
//         _logger.info(
//           "Temporary image file deleted: ${imageIdToRemove.file.path}",
//         );
//       } catch (e, s) {
//         _logger.warning(
//           "Failed to delete temporary image file ${imageIdToRemove.file.path}: $e",
//           s,
//         );
//       }
//     } else if (imageIdToRemove is GuidIdentifier) {
//       _logger.info(
//         "Image with GUID ${imageIdToRemove.guid} marked for removal from location's list.",
//       );
//       // Actual deletion from storage will happen during saveLocation
//     }
//   }
//
//   bool _validateForm() {
//     return _validateFormCallback();
//   }
//
//   Future<List<String>> _processImagesForSave(
//     List<ImageIdentifier> currentImageIdentifiers,
//     List<String> initialImageGuids,
//   ) async {
//     List<String> finalImageGuidsForLocation = [];
//
//     if (_imageDataService != null) {
//       final imageService = _imageDataService;
//
//       // 1. Save new temporary images
//       for (var identifier in currentImageIdentifiers) {
//         if (identifier is TempFileIdentifier) {
//           try {
//             final String savedGuid = await imageService.saveUserImage(
//               identifier.file,
//             );
//             finalImageGuidsForLocation.add(savedGuid);
//             _logger.info(
//               "Saved temp image ${identifier.file.path} as GUID: $savedGuid",
//             );
//           } catch (e, s) {
//             _logger.severe(
//               "Failed to save image ${identifier.file.path}: $e",
//               s,
//             );
//             throw Exception("Failed to save image ${identifier.file.path}: $e");
//           }
//         } else if (identifier is GuidIdentifier) {
//           finalImageGuidsForLocation.add(identifier.guid);
//         }
//       }
//
//       // 2. Delete images that were removed from the list
//       Set<String> currentPersistedGuids = currentImageIdentifiers
//           .whereType<GuidIdentifier>()
//           .map((gi) => gi.guid)
//           .toSet();
//       List<String> guidsToDeletePermanently = _savedImageGuids
//           .where((initialGuid) => !currentPersistedGuids.contains(initialGuid))
//           .toList();
//
//       for (String guidToDelete in guidsToDeletePermanently) {
//         try {
//           _logger.info(
//             "Permanently deleting image GUID: $guidToDelete as it was removed from location.",
//           );
//           await imageService.deleteUserImage(guidToDelete);
//         } catch (e, s) {
//           _logger.severe("Failed to delete image GUID $guidToDelete: $e", s);
//           throw Exception("Failed to delete image GUID $guidToDelete: $e");
//         }
//       }
//     } else {
//       // ImageDataService is null
//       if (currentImageIdentifiers.any((img) => img is TempFileIdentifier)) {
//         _logger.severe(
//           "Cannot save new images: IImageDataService is not available.",
//         );
//         for (var identifier in currentImageIdentifiers) {
//           if (identifier is TempFileIdentifier) {
//             try {
//               await _tempFileService.deleteFile(identifier.file);
//               _logger.info(
//                 "Cleaned up unsaved temp image: ${identifier.file.path}",
//               );
//             } catch (e) {
//               _logger.warning(
//                 "Failed to cleanup unsaved temp image ${identifier.file.path}: $e",
//               );
//             }
//           }
//         }
//         throw Exception(
//           "Cannot save new images as the image service is unavailable.",
//         );
//       }
//       _logger.warning(
//         "IImageDataService is null. Proceeding without image saving/deletion capabilities.",
//       );
//       finalImageGuidsForLocation = currentImageIdentifiers
//           .whereType<GuidIdentifier>()
//           .map((gi) => gi.guid)
//           .toList();
//     }
//     return finalImageGuidsForLocation;
//   }
//
//   Future<void> _saveLocationData(Location locationToSave) async {
//     if (_isNewLocation) {
//       await _dataService.addLocation(locationToSave);
//       _logger.info("New location added successfully: ${locationToSave.id}");
//     } else {
//       await _dataService.updateLocation(locationToSave);
//       _logger.info("Location updated successfully: ${locationToSave.id}");
//     }
//   }
//
//   Future<bool> saveLocation() async {
//     if (_isSaving) return false;
//     if (!_validateForm()) {
//       _logger.warning("Validation failed. Cannot save location.");
//       return false;
//     }
//
//     _isSaving = true;
//     notifyListeners();
//
//     try {
//       final List<String> finalImageGuids = await _processImagesForSave(
//         List.from(_currentImages),
//         List.from(_savedImageGuids),
//       );
//
//       final locationToSave = Location(
//         id: _initialLocation?.id ?? const Uuid().v4(),
//         name: nameController.text.trim(),
//         description: descriptionController.text.trim().isEmpty
//             ? null
//             : descriptionController.text.trim(),
//         address: addressController.text.trim().isEmpty
//             ? null
//             : addressController.text.trim(),
//         imageGuids: finalImageGuids.isEmpty ? null : finalImageGuids,
//       );
//
//       await _saveLocationData(locationToSave);
//
//       await _cleanupTempDir();
//       _isSaving = false;
//       notifyListeners();
//       return true;
//     } catch (e, s) {
//       _logger.severe("Error saving location or processing images: $e", s);
//       await _cleanupTempDir();
//       _isSaving = false;
//       notifyListeners();
//       return false;
//     }
//   }
//
//   Widget getImageThumbnailWidget(
//     ImageIdentifier identifier, {
//     required double width,
//     required double height,
//     required BoxFit fit,
//   }) {
//     if (identifier is GuidIdentifier) {
//       if (_imageDataService == null) {
//         _logger.warning(
//           "IImageDataService is null in ViewModel, cannot display persisted image for GUID: ${identifier.guid}",
//         );
//         return SizedBox(
//           // Return a SizedBox or a more specific placeholder
//           width: width,
//           height: height,
//           child: const Center(
//             child: Icon(Icons.error_outline, color: Colors.red, size: 50),
//           ),
//         );
//       }
//
//       return _imageDataService.getUserImage(
//         identifier.guid,
//         width: width,
//         height: height,
//         fit: fit,
//       );
//     } else if (identifier is TempFileIdentifier) {
//       return Image.file(
//         identifier.file,
//         width: width,
//         height: height,
//         fit: fit,
//         errorBuilder: (context, error, stackTrace) {
//           _logger.severe(
//             "Error loading TEMP image ${identifier.file.path} in ViewModel: $error",
//             error,
//             stackTrace,
//           );
//           return SizedBox(
//             // Return a SizedBox or a more specific placeholder
//             width: width,
//             height: height,
//             child: const Center(
//               child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
//             ),
//           );
//         },
//       );
//     }
//     // Fallback for unknown types, though ideally your ImageIdentifier hierarchy is sealed/exhaustive
//     _logger.warning(
//       "Unknown ImageIdentifier type encountered in ViewModel.getImageThumbnailWidget: ${identifier.runtimeType}",
//     );
//     return SizedBox(
//       width: width,
//       height: height,
//       child: const Center(child: Icon(Icons.help_outline)),
//     );
//   }
//
//   bool _isHandlingExitAttempt = false;
//
//   bool get hasUnsavedChanges {
//     // 1. Check text fields
//     if (nameController.text.trim() != (_initialLocation?.name ?? '').trim()) {
//       _logger.finer("Unsaved change: Name differs.");
//       return true;
//     }
//     if (descriptionController.text.trim() !=
//         (_initialLocation?.description ?? '').trim()) {
//       _logger.finer("Unsaved change: Description differs.");
//       return true;
//     }
//     if (addressController.text.trim() !=
//         (_initialLocation?.address ?? '').trim()) {
//       _logger.finer("Unsaved change: Address differs.");
//       return true;
//     }
//
//     // 2. Check images
//     // Compare current images (GUIDs of persisted images + TempFileIdentifiers for new ones)
//     // with initial persisted GUIDs.
//
//     // Get GUIDs of currently displayed images that were initially persisted
//     final Set<String> currentPersistedGuidsInUi = _currentImages
//         .whereType<GuidIdentifier>()
//         .map((gi) => gi.guid)
//         .toSet();
//
//     // Get GUIDs that were initially present
//     final Set<String> initialPersistedGuidsSet = _savedImageGuids.toSet();
//
//     // Check if any initially persisted image has been removed
//     if (initialPersistedGuidsSet
//         .difference(currentPersistedGuidsInUi)
//         .isNotEmpty) {
//       _logger.finer(
//         "Unsaved change: An initially persisted image was removed.",
//       );
//       return true;
//     }
//     // Check if any persisted image currently in UI wasn't there initially (shouldn't happen if logic is correct, but good for safety)
//     if (currentPersistedGuidsInUi
//         .difference(initialPersistedGuidsSet)
//         .isNotEmpty) {
//       _logger.finer(
//         "Unsaved change: A persisted image was added that wasn't initial (unexpected).",
//       );
//       return true;
//     }
//
//     // Check if any new (temporary) images have been added
//     if (_currentImages.any((img) => img is TempFileIdentifier)) {
//       _logger.finer("Unsaved change: New temporary image(s) added.");
//       return true;
//     }
//
//     // If it's a new location and any field is filled or an image is added, it's an unsaved change.
//     // However, the checks above already cover this implicitly.
//     // For a new location, _initialLocation is null, so initial values are empty strings/lists.
//     // Any text input or image addition will trigger `true` from the checks above.
//
//     _logger.finer("No unsaved changes detected.");
//     return false;
//   }
//
//   Future<void> handleDiscardOrPop(BuildContext context) async {
//     if (_isHandlingExitAttempt) {
//       _logger.info("Exit attempt already in progress. Ignoring.");
//       return;
//     }
//     _isHandlingExitAttempt = true;
//
//     try {
//       _logger.info(
//         "handleDiscardOrPop called. isSaving: $isSaving, isPickingImage: $isPickingImage",
//       );
//       if (isSaving || isPickingImage) {
//         _logger.info("Navigation blocked by isSaving or isPickingImage.");
//         return;
//       }
//
//       if (hasUnsavedChanges && context.mounted) {
//         final bool? discard = await showDialog<bool>(
//           context: context,
//           builder: (BuildContext dialogContext) => AlertDialog(
//             title: const Text('Unsaved Changes'),
//             content: const Text(
//               'You have unsaved changes. Do you want to discard them?',
//             ),
//             actions: <Widget>[
//               TextButton(
//                 child: const Text('Cancel'),
//                 onPressed: () => Navigator.of(dialogContext).pop(false),
//               ),
//               TextButton(
//                 child: const Text('Discard'),
//                 onPressed: () => Navigator.of(dialogContext).pop(true),
//               ),
//             ],
//           ),
//         );
//         if (discard != true) {
//           _logger.info("User chose not to discard changes.");
//           return;
//         }
//       }
//
//       // If we reach here, either no unsaved changes or user confirmed discard
//       if (context.mounted && Navigator.of(context).canPop()) {
//         _logger.info("Popping from handleDiscardOrPop.");
//         Navigator.of(context).pop();
//       }
//     } finally {
//       _isHandlingExitAttempt = false;
//     }
//
//     await _cleanupTempDir();
//   }
//
//   Future<void> _cleanupTempDir() async {
//     if (_tempDir != null && await _tempDir!.exists()) {
//       try {
//         await _tempFileService.deleteDirectory(_tempDir!);
//         _logger.info("Cleaned up temporary image directory: ${_tempDir!.path}");
//         _tempDir = null;
//       } catch (e, s) {
//         _logger.warning(
//           "Failed to clean up temporary image directory ${_tempDir!.path}: $e",
//           s,
//         );
//       }
//     }
//   }
//
//   bool _isDisposed = false;
//   bool get isDisposed => _isDisposed;
//
//   @override
//   void dispose() {
//     if (_isDisposed) return;
//
//     _logger.finer("Disposing EditLocationViewModel.");
//     nameController.dispose();
//     descriptionController.dispose();
//     addressController.dispose();
//
//     if (_tempDir != null) {
//       _logger.warning(
//         "ViewModel disposed, but temp directory was not cleaned up. Attempting cleanup now. This might indicate an unhandled exit path.",
//       );
//
//       _cleanupTempDir().catchError((e, s) {
//         _logger.severe("Error during fallback cleanup in dispose: $e", s);
//       });
//     }
//
//     _isDisposed = true;
//     super.dispose();
//   }
// }
