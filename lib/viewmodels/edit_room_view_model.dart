import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../core/image_identifier.dart';
import '../core/image_source_type_enum.dart';
import '../models/room_model.dart';
import '../models/location_model.dart';
import '../services/data_service_interface.dart';
import '../services/image_picker_service_interface.dart';
import '../services/image_data_service_interface.dart';
import '../services/temporary_file_service_interface.dart';

// legacy support
import '../services/image_data_service_legacy_shim.dart';

final Logger _logger = Logger('EditRoomVM');

class EditRoomViewModel extends ChangeNotifier /*with HasImagePicking*/ {
  final IDataService _dataService;
  // final IImagePickerService _imagePickerService;
  final IImageDataService? _imageDataService;
  final ITemporaryFileService _tempFileService;

  final Location _parentLocation;
  final Room? _initialRoom;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  final TextEditingController _nameController = TextEditingController();
  TextEditingController get nameController => _nameController;

  final TextEditingController _descriptionController = TextEditingController();
  TextEditingController get descriptionController => _descriptionController;

  List<ImageIdentifier> _currentImages = [];
  List<ImageIdentifier> get currentImages => List.unmodifiable(_currentImages);
  List<String> _initialPersistedGuids = [];
  Directory? _sessionTempDir;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool get isNewRoom => _initialRoom == null;

  String get appBarTitle => isNewRoom
      ? 'Add New Room to ${_parentLocation.name}'
      : 'Edit Room: ${_initialRoom?.name ?? ''}';

  EditRoomViewModel({
    required IDataService dataService,
    required IImagePickerService imagePickerService,
    required IImageDataService imageDataService,
    required ITemporaryFileService tempFileService,
    required Location parentLocation,
    Room? initialRoom,
  }) : _dataService = dataService,
       // _imagePickerService = imagePickerService,
       _imageDataService = imageDataService,
       _tempFileService = tempFileService,
       _parentLocation = parentLocation,
       _initialRoom = initialRoom {
    _logger.info(
      "EditRoomViewModel created. New room: $isNewRoom for location '${_parentLocation.name}'. Initial room: ${_initialRoom?.name}",
    );

    // wire mixin deps
    // imagePicker = ImagePickerController(
    //   picker: imagePickerService,
    //   store: imageDataService,
    //   temp: tempFileService,
    // );

    _initialize();
  }

  void _initialize() {
    if (_initialRoom != null) {
      _nameController.text = _initialRoom.name;
      _descriptionController.text = _initialRoom.description ?? '';
      _initialPersistedGuids = List.from(_initialRoom.imageGuids ?? []);
      _currentImages = _initialPersistedGuids.map((guid) => GuidIdentifier(guid)).toList();
    } else {
      _initialPersistedGuids = [];
      _currentImages = [];
    }

    if (_imageDataService == null) {
      _initializeSessionTempDir();
    }

    _nameController.addListener(_handleFieldChange);
    _descriptionController.addListener(_handleFieldChange);
  }

  Future<void> _initializeSessionTempDir() async {
    try {
      // await _tempFileService.init(sessionPrefix: 'edit_room_session');
      _logger.info("Session temporary directory initialized");
    } catch (e, s) {
      _logger.severe("Failed to initialize session temporary directory", e, s);
    }
  }

  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  void _handleFieldChange() {
    if (isNewRoom) {
      _hasUnsavedChanges =
          _nameController.text.isNotEmpty ||
          _descriptionController.text.isNotEmpty ||
          _currentImages.isNotEmpty;
    } else if (_initialRoom != null) {
      bool nameChanged = _nameController.text != _initialRoom.name;
      bool descriptionChanged = _descriptionController.text != (_initialRoom.description ?? '');

      List<String> currentGuidsForComparison = _currentImages
          .whereType<GuidIdentifier>()
          .map((gi) => gi.guid)
          .toList();
      bool hasTempFiles = _currentImages.any((img) => img is TempFileIdentifier);

      bool imagesChanged =
          hasTempFiles ||
          !const ListEquality().equals(currentGuidsForComparison, _initialPersistedGuids);

      _hasUnsavedChanges = nameChanged || descriptionChanged || imagesChanged;
    }
    _logger.finest(
      "Unsaved changes status: $_hasUnsavedChanges. Current images count: ${_currentImages.length}",
    );
  }

  Future<void> pickImageFromCamera() async {
    _logger.info("Attempting to pick image from camera via helper...");
    await _pickImageWithHelper(ImageSourceType.camera);
  }

  Future<void> pickImageFromGallery() async {
    _logger.info("Attempting to pick image from gallery via helper...");
    await _pickImageWithHelper(ImageSourceType.gallery);
  }

  Future<void> _pickImageWithHelper(ImageSourceType source) async {
    // if (_isPickingImage) return;
    // _isPickingImage = true;
    notifyListeners();

    // Determine direct save based on ImageDataService availability for Rooms
    bool directSave = _imageDataService != null;

    if (!directSave && _sessionTempDir == null) {
      _logger.severe(
        "Cannot pick image: Session temporary directory is not initialized, and direct save is not possible.",
      );
      // _isPickingImage = false;
      notifyListeners();
      return;
    }

    _logger.finer(
      "Calling helper. Direct save: $directSave. Session temp dir: ${_sessionTempDir?.path}",
    );

    try {
      // final ImageIdentifier? newImageId = await pickOne(
      //   source: source,
      //   directSaveWithImageDataService: directSave,
      //   sessionTempDir: _sessionTempDir, // Pass Room's session temp dir
      // );
      //
      // if (newImageId != null) {
      //   _currentImages.add(newImageId);
      //   _handleFieldChange(); // Existing method
      //   notifyListeners();
      // }
    } catch (e, s) {
      _logger.severe("Error reported from ImagePickingHelper to EditRoomViewMode", e, s);
      // Handle error as needed
    } finally {
      // _isPickingImage = false;
      notifyListeners();
    }
  }

  // Future<void> _pickImage(ImageSourceType source) async {
  //   final File? pickedFileFromPicker;
  //   try {
  //     if (source == ImageSourceType.camera) {
  //       pickedFileFromPicker = await _imagePickerService.pickImageFromCamera();
  //     } else {
  //       pickedFileFromPicker = await _imagePickerService.pickImageFromGallery();
  //     }
  //
  //     if (pickedFileFromPicker != null) {
  //       if (_imageDataService != null) {
  //         _logger.finer("Image picked: ${pickedFileFromPicker.path}. Saving to permanent storage via ImageDataService...");
  //         final String imageGuid = await _imageDataService!.saveUserImage(pickedFileFromPicker);
  //         _currentImages.add(GuidIdentifier(imageGuid));
  //         _logger.info("Image saved with GUID: $imageGuid and added to current images.");
  //         try {
  //           await pickedFileFromPicker.delete();
  //         } catch (e) {
  //           _logger.warning("Failed to delete picker's temp file ${pickedFileFromPicker.path}: $e");
  //         }
  //       } else {
  //         if (_sessionTempDir == null) {
  //           _logger.severe("Cannot pick image: Session temporary directory is not initialized and ImageDataService is null.");
  //           return;
  //         }
  //         _logger.finer("Image picked: ${pickedFileFromPicker.path}. ImageDataService is null. Copying to session temp dir...");
  //
  //         final File tempCopiedFile = await _tempFileService.copyToTempDir(pickedFileFromPicker, _sessionTempDir!);
  //         _currentImages.add(TempFileIdentifier(tempCopiedFile));
  //         _logger.info("Image copied to session temp: ${tempCopiedFile.path}");
  //         try {
  //           await pickedFileFromPicker.delete();
  //         } catch (e) {
  //            _logger.warning("Failed to delete picker's temp file ${pickedFileFromPicker.path} after copying to session: $e");
  //         }
  //       }
  //       _handleFieldChange();
  //       notifyListeners();
  //     } else {
  //       _logger.info("Image picking cancelled or failed (null file returned).");
  //     }
  //   } catch (e, s) {
  //     _logger.severe('Error picking/processing image: $e', e, s);
  //   }
  // }

  // Future<void> pickImageFromCamera() async {
  //   _logger.info("Attempting to pick image from camera...");
  //   await _pickImage(ImageSourceType.camera);
  // }
  //
  // Future<void> pickImageFromGallery() async {
  //   _logger.info("Attempting to pick image from gallery...");
  //   await _pickImage(ImageSourceType.gallery);
  // }

  Future<void> removeImage(int index) async {
    if (index < 0 || index >= _currentImages.length) {
      _logger.warning("Invalid index for image removal: $index");
      return;
    }

    final imageIdToRemove = _currentImages.removeAt(index);
    _logger.info("Attempting to remove image at index $index, Identifier: $imageIdToRemove");

    _handleFieldChange();
    notifyListeners();

    if (imageIdToRemove is TempFileIdentifier) {
      try {
        // await _tempFileService.deleteFile(imageIdToRemove.file);
        _logger.info("Temporary image file deleted: ${imageIdToRemove.file.path}");
      } catch (e, s) {
        _logger.warning(
          "Failed to delete temporary "
          "image file ${imageIdToRemove.file.path}",
          e,
          s,
        );
      }
    } else if (imageIdToRemove is GuidIdentifier) {
      _logger.info(
        "Image GUID ${imageIdToRemove.guid} removed from current list. Will be processed on save.",
      );
    }
  }

  Widget getImageThumbnailWidget(
    ImageIdentifier identifier, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    width ??= 100;
    height ??= 100;
    fit ??= BoxFit.cover;

    if (identifier is GuidIdentifier) {
      if (_imageDataService == null) {
        _logger.warning(
          "ImageDataService is null, cannot display persisted image for GUID: ${identifier.guid}",
        );
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
      return _imageDataService.getUserImage(
        identifier.guid,
        width: width,
        height: height,
        fit: fit,
      );
    } else if (identifier is TempFileIdentifier) {
    } else if (identifier is TempFileIdentifier) {
      return Image.file(
        identifier.file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, e, s) {
          _logger.severe("Error loading TEMP image ${identifier.file.path} in ViewModel", e, s);
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
    _logger.warning(
      "Unknown ImageIdentifier type in getImageThumbnailWidget: ${identifier.runtimeType}",
    );
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.help_outline, color: Colors.grey),
    );
  }

  Future<List<String>> _processImagesForSave() async {
    List<String> finalImageGuidsForRoom = [];

    if (_imageDataService != null) {
      final imageService = _imageDataService;

      for (var identifier in _currentImages) {
        if (identifier is TempFileIdentifier) {
          try {
            _logger.info("Processing TempFileIdentifier for save: ${identifier.file.path}");
            final String savedGuid = await imageService.saveUserImage(identifier.file);
            finalImageGuidsForRoom.add(savedGuid);
            // await _tempFileService.deleteFile(identifier.file);
          } catch (e, s) {
            _logger.severe(
              "Failed to save temp image ${identifier.file.path} during "
              "final save",
              e,
              s,
            );
            throw Exception("Failed to save image ${identifier.file.path}");
          }
        } else if (identifier is GuidIdentifier) {
          finalImageGuidsForRoom.add(identifier.guid);
        }
      }

      Set<String> currentPersistedGuidsInFinalList = finalImageGuidsForRoom.toSet();
      List<String> guidsToDeletePermanently = _initialPersistedGuids
          .where((initialGuid) => !currentPersistedGuidsInFinalList.contains(initialGuid))
          .toList();

      for (String guidToDelete in guidsToDeletePermanently) {
        try {
          _logger.info("Permanently deleting room image GUID: $guidToDelete as it was removed.");
          await imageService.deleteUserImage(guidToDelete);
        } catch (e, s) {
          _logger.severe("Failed to delete room image GUID $guidToDelete", e, s);
        }
      }
    } else {
      if (_currentImages.any((img) => img is TempFileIdentifier)) {
        _logger.severe(
          "Cannot save room: New images were picked but IImageDataService is not available.",
        );
        for (var identifier in _currentImages.whereType<TempFileIdentifier>()) {
          try {
            // await _tempFileService.deleteFile(identifier.file);
          } catch (_) {}
        }
        throw Exception("Cannot save new images as the image service is unavailable.");
      }
      finalImageGuidsForRoom = _currentImages
          .whereType<GuidIdentifier>()
          .map((gi) => gi.guid)
          .toList();
      _logger.warning(
        "IImageDataService is null. Proceeding with only previously persisted image GUIDs for room.",
      );
    }
    return finalImageGuidsForRoom;
  }

  Future<bool> saveRoom() async {
    if (!_formKey.currentState!.validate()) {
      _logger.info("Form validation failed. Room save aborted.");
      return false;
    }
    _isSaving = true;
    notifyListeners();
    _logger.info("Attempting to save room. New room: $isNewRoom. Name: '${_nameController.text}'");

    try {
      final List<String> finalImageGuids = await _processImagesForSave();

      final roomData = Room(
        id: _initialRoom?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        locationId: _parentLocation.id,
        imageGuids: finalImageGuids.isEmpty ? null : finalImageGuids,
        createdAt: _initialRoom?.createdAt,
      );

      if (isNewRoom) {
        await _dataService.addRoom(roomData);
        _logger.info(
          "New room '${roomData.name}' added successfully to location '${_parentLocation.name}'.",
        );
      } else {
        await _dataService.updateRoom(roomData);
        _logger.info(
          "Room '${roomData.name}' updated successfully in location '${_parentLocation.name}'.",
        );
      }

      _hasUnsavedChanges = false;
      _initialPersistedGuids = List.from(finalImageGuids);
      _currentImages = finalImageGuids.map((guid) => GuidIdentifier(guid)).toList();

      return true;
    } catch (e, s) {
      _logger.severe('Failed to save room', e, s);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> handleDiscardOrPop() async {
    _logger.info("EditRoomViewModel handling discard/pop. Cleaning up session resources.");
    // await _tempFileService.clearSession();
  }

  @override
  void dispose() {
    _logger.info("Disposing EditRoomViewModel for room: ${_initialRoom?.name ?? 'New Room'}");
    _nameController.removeListener(_handleFieldChange);
    _descriptionController.removeListener(_handleFieldChange);
    _nameController.dispose();
    _descriptionController.dispose();

    // _tempFileService.dispose();

    super.dispose();
  }
}
