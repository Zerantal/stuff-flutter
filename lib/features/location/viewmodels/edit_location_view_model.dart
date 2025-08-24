// lib/features/location/viewmodels/edit_location_view_model.dart

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../../core/image_identifier.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../shared/image/image_ref.dart';
import '../../../shared/image/image_identifier_to_ref.dart' as id2ref;
import '../../../shared/image/image_identifier_persistence.dart' as persist;
import '../../../domain/models/location_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/location_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../services/ops/db_ops.dart';
import '../state/edit_location_state.dart';

final Logger _log = Logger('EditLocationViewModel');

/// ViewModel for the Edit Location page.
///
/// Notes:
///     1) `_imageIds` ([List<ImageIdentifier>]) — truth for persistence (guid vs temp file)
///     2) `_state.images` ([List<ImageRef>]) — ready-to-render UI images
/// - On save:
///     - TempFileIdentifier entries are persisted via ImagePickerController.persistTemp(...)
///     - GuidIdentifier entries are kept as-is
class EditLocationViewModel extends ChangeNotifier {
  final IDataService _data;
  final IImageDataService _imageStore;
  final ILocationService _geo;
  final ITemporaryFileService _tmpFileSvc;
  final String? _locationId;
  final DbOps _dbOps;

  bool _isInitialising;
  bool get isInitialising => _isInitialising;

  void setInitialising(bool v) {
    if (_isInitialising == v) return;
    _isInitialising = v;
    notifyListeners();
  }

  EditLocationViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
    required ILocationService locationService,
    required ITemporaryFileService tempFileService,
    required String? locationId,
  }) : _data = dataService,
       _imageStore = imageDataService,
       _geo = locationService,
       _tmpFileSvc = tempFileService,
       _locationId = locationId,
       _isInitialising = locationId != null,
       _dbOps = DbOps(dataService, imageDataService);

  final uuid = const Uuid();

  // Form / state
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();

  // State
  EditLocationState _state = const EditLocationState(name: '', isNewLocation: true);
  EditLocationState get state => _state;

  // Expose bits the page expects
  bool get isNewLocation => _state.isNewLocation;
  bool get isSaving => _state.isSaving;
  bool get isGettingLocation => _state.isGettingLocation;
  bool get deviceHasLocationService => _state.deviceHasLocationService;
  bool get hasUnsavedChanges => _state.hasUnsavedChanges;
  bool get hasTempSession => _state.hasTempSession;

  // Images for UI:
  List<ImageRef> get images => _state.images;

  // Underlying identifiers we persist on save (kept in index-lockstep with _state.images)
  final List<ImageIdentifier> _imageIds = [];

  // Temp session for storing picked images
  TempSession? _tempSession;
  TempSession? get tempSession => _tempSession;

  Location? _loadedLocation;

  // ----- Lifecycle ----------------------------------------------------------
  Future<void> init() async {
    // editing an existing location, pull it from the DB
    if (_locationId != null) {
      _loadedLocation = await _data.getLocationById(_locationId);

      if (_loadedLocation != null) {
        nameController.text = _loadedLocation!.name;
        descriptionController.text = _loadedLocation!.description ?? '';
        addressController.text = _loadedLocation!.address ?? '';

        // Build identifiers from persisted GUIDs
        _imageIds
          ..clear()
          ..addAll(
            (_loadedLocation!.imageGuids)
                .where((g) => g.isNotEmpty)
                .map<GuidIdentifier>((g) => GuidIdentifier(g)),
          );

        // Map to ImageRef for UI
        final refs = await id2ref.toImageRefs(_imageIds, _imageStore);

        _state = _state.copyWith(
          name: _loadedLocation!.name,
          description: _loadedLocation!.description ?? '',
          address: _loadedLocation!.address ?? '',
          images: refs,
          isNewLocation: false,
          hasUnsavedChanges: false,
        );
      }
    }

    final String sessionLabel;
    if (_locationId != null) {
      sessionLabel = 'edit_room_$_locationId';
    } else {
      sessionLabel = 'add_room_${uuid.v4()}';
    }

    _tempSession = await _tmpFileSvc.startSession(label: sessionLabel);
    _state = _state.copyWith(hasTempSession: true);

    // React to user typing to flip hasUnsavedChanges
    nameController.addListener(_onAnyFieldChanged);
    descriptionController.addListener(_onAnyFieldChanged);
    addressController.addListener(_onAnyFieldChanged);
    notifyListeners();

    setInitialising(false);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    _tempSession?.dispose();
    super.dispose();
  }

  // ----- Internal helpers ---------------------------------------------------

  // update form state data model
  void _onAnyFieldChanged() {
    final next = _state.copyWith(
      name: nameController.text,
      description: descriptionController.text,
      address: addressController.text,
      hasUnsavedChanges: true,
    );

    if (next != _state) {
      _state = next;
      notifyListeners(); // <- needed so the UI reacts to hasUnsavedChanges updates
    }
  }

  // ----- Image picking ------------------------------------------------------

  void onImagePicked(ImageIdentifier id, ImageRef ref) {
    // maintain list lockstep
    _imageIds.add(id);
    _state = _state.copyWith(images: [..._state.images, ref], hasUnsavedChanges: true);
    notifyListeners();
  }

  void removeImage(int index) {
    if (index < 0 || index >= _state.images.length) return;
    final nextRefs = List<ImageRef>.from(_state.images);
    nextRefs.removeAt(index);

    final nextIds = List<ImageIdentifier>.from(_imageIds);
    if (index < nextIds.length) {
      nextIds.removeAt(index);
    }

    _imageIds
      ..clear()
      ..addAll(nextIds);
    _state = _state.copyWith(images: nextRefs, hasUnsavedChanges: true);
    notifyListeners();
  }

  // ----- Geocoding / address -------------------------------------------------

  /// Attempts to resolve the current address and update the form.
  /// Returns true on success (non-empty address), false otherwise.
  Future<bool> getCurrentAddress() async {
    if (_state.isGettingLocation) return false;

    _state = _state.copyWith(
      isGettingLocation: true,
      // optimistic; will flip on error
      deviceHasLocationService: true,
    );
    notifyListeners();

    try {
      final addr = await _geo.getCurrentAddress();
      final ok = addr != null && addr.trim().isNotEmpty;

      if (ok) {
        final trimmed = addr.trim();
        addressController.text = trimmed;
        _state = _state.copyWith(
          address: trimmed,
          hasUnsavedChanges: true,
          deviceHasLocationService: true,
        );
      } else {
        _log.warning('getCurrentAddress returned null/empty');
      }

      return ok;
    } catch (e, s) {
      _log.severe('getCurrentAddress failed', e, s);
      _state = _state.copyWith(deviceHasLocationService: false);
      return false;
    } finally {
      _state = _state.copyWith(isGettingLocation: false);
      notifyListeners();
    }
  }

  Future<void> deleteLocation() => _dbOps.deleteLocation(_loadedLocation!.id);

  // ----- Save ---------------------------------------------------------------

  /// Validates form and persists the Location (and any temp images).
  ///
  /// Returns true if save succeeded.
  Future<bool> saveLocation() async {
    if (_state.isSaving) return false;

    // Validate the form if a validator is wired.
    final form = formKey.currentState;
    if (form != null && !form.validate()) return false;

    _state = _state.copyWith(isSaving: true);
    notifyListeners();

    try {
      // A) Remember what was previously persisted for this location
      final previousGuids = (_loadedLocation?.imageGuids ?? const <String>[]).toSet();

      // B) Persist any temp files → GUIDs (order preserved)
      final guids = await persist.persistTempImages(
        _imageIds,
        _imageStore,
        deleteTempOnSuccess: true, // cleanup
      );

      // C) Replace temp identifiers in the VM with their new GUIDs
      for (var i = 0; i < _imageIds.length; i++) {
        if (_imageIds[i] is TempFileIdentifier) {
          _imageIds[i] = GuidIdentifier(guids[i]);
        }
      }

      // D) Build new model and save it
      final toSave = (_loadedLocation ?? Location(name: 'dummy_name')).copyWith(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
        imageGuids: guids,
      );

      // E) After the model is persisted, delete orphaned images
      final newGuids = guids.toSet();
      final toDelete = previousGuids.difference(newGuids);
      if (toDelete.isNotEmpty) {
        await _imageStore.deleteImages(toDelete); // best-effort
      }

      if (_loadedLocation == null) {
        await _data.addLocation(toSave);
        _loadedLocation = toSave; // locally consider it the current
        _state = _state.copyWith(isNewLocation: false);
      } else {
        await _data.updateLocation(toSave);
        _loadedLocation = toSave;
      }

      _state = _state.copyWith(hasUnsavedChanges: false);
      return true;
    } catch (e, s) {
      _log.severe('saveLocation failed', e, s);
      return false;
    } finally {
      _state = _state.copyWith(isSaving: false);
      notifyListeners();
    }
  }
}
