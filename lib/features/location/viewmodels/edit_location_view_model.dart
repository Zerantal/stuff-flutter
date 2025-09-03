// lib/features/location/viewmodels/edit_location_view_model.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../../core/image_identifier.dart';
import '../../../core/util/string_util.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../shared/forms/suppressible_text_editing_controller.dart';
import '../../../domain/models/location_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/location_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../services/ops/db_ops.dart';
import '../../shared/edit/geolocate_mixin.dart';
import '../../shared/edit/image_picking_mixin.dart';
import '../../shared/edit/state_management_mixin.dart';
import '../../shared/state/image_set.dart';
import '../state/edit_location_state.dart';

// final Logger _log = Logger('EditLocationViewModel');

/// ViewModel for the Edit Location page.
///
/// Notes:
///     1) `_imageIds` ([List<ImageIdentifier>]) — truth for persistence (guid vs temp file)
///     2) `_state.images` ([List<ImageRef>]) — ready-to-render UI images
/// - On save:
///     - TempImageIdentifier entries are persisted via ImagePickerController.persistTemp(...)
///     - PersistentImageIdentifier entries are kept as-is
class EditLocationViewModel extends ChangeNotifier
    with StateManagementMixin<EditLocationState>, GeolocateMixin, ImageEditingMixin {
  EditLocationViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
    required ILocationService locationService,
    required ITemporaryFileService tempFileService,
  }) : _data = dataService,
       _imageStore = imageDataService,
       _dbOps = DbOps(dataService, imageDataService) {
    configureGeolocate(locationService: locationService);

    configureImageEditing(
      imageStore: imageDataService,
      tempFiles: tempFileService,
      updateImages: ({required ImageSet images, bool notify = true}) {
        _imageListRevision++;

        updateState((s) => s.copyWith(images: images), notify: notify);
      },
    );
  }

  // ------------------ Context-aware convenience factories --------------------

  static EditLocationViewModel forEdit(BuildContext ctx, {required String locationId}) {
    final vm = EditLocationViewModel(
      dataService: ctx.read<IDataService>(),
      imageDataService: ctx.read<IImageDataService>(),
      tempFileService: ctx.read<ITemporaryFileService>(),
      locationService: ctx.read<ILocationService>(),
    );
    scheduleMicrotask(() => vm.initForEdit(locationId));
    return vm;
  }

  static EditLocationViewModel forNew(BuildContext ctx) {
    final vm = EditLocationViewModel(
      dataService: ctx.read<IDataService>(),
      imageDataService: ctx.read<IImageDataService>(),
      tempFileService: ctx.read<ITemporaryFileService>(),
      locationService: ctx.read<ILocationService>(),
    );
    scheduleMicrotask(() => vm.initForNew());
    return vm;
  }
  // ----------------------------------------------------------------------------------

  final IDataService _data;
  final IImageDataService _imageStore;
  final DbOps _dbOps;

  final uuid = const Uuid();

  // Form / state
  final formKey = GlobalKey<FormState>();
  final nameController = SuppressibleTextEditingController();
  final descriptionController = SuppressibleTextEditingController();
  final addressController = SuppressibleTextEditingController();

  Location? _loadedLocation;

  late bool _isNewLocation;
  bool get isNewLocation => _isNewLocation;

  // Image list revision counter (cheap O(1) change signal)
  int _imageListRevision = 0;
  int get imageListRevision => _imageListRevision;

  // ----- Lifecycle ----------------------------------------------------------

  Future<void> initForEdit(String locationId) async {
    _isNewLocation = false;

    await initialiseStateAsync(() async {
      _loadedLocation = await _data.getLocationById(locationId);

      if (_loadedLocation != null) {
        nameController.text = _loadedLocation!.name;
        descriptionController.text = _loadedLocation!.description ?? '';
        addressController.text = _loadedLocation!.address ?? '';

        return EditLocationState(
          name: _loadedLocation!.name,
          description: _loadedLocation!.description ?? '',
          address: _loadedLocation!.address ?? '',
          images: ImageSet.fromGuids(_imageStore, _loadedLocation!.imageGuids),
        );
      }
      throw Exception('Location not found');
    });

    if (!isInitialised) return;

    // create session for storing temp files
    final String sessionLabel = concatenateFirstTenChars(['edit_loc', locationId]);
    await startImageSession(sessionLabel);
    seedExistingImages(currentState.images, notify: false);

    initTextControllers();
  }

  Future<void> retryInitForEdit(String locationId) async {
    clearInitialLoadError();
    await initForEdit(locationId);
  }

  Future<void> initForNew() async {
    _isNewLocation = true;

    initialiseState(EditLocationState());

    // create session for storing temp files
    final String sessionLabel = concatenateFirstTenChars(['add_loc', (uuid.v4())]);
    await startImageSession(sessionLabel);

    initTextControllers();
  }

  void initTextControllers() {
    nameController.addListener(() => setName(nameController.text));
    descriptionController.addListener(() => setDescription(descriptionController.text));
    addressController.addListener(() => setAddress(addressController.text));
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    disposeImageSession(); // deletes temp files, doesn't notify
    super.dispose();
  }

  // ===========================================================================
  // Field setters
  // ===========================================================================

  void setName(String v) {
    updateState((s) => s.copyWith(name: v));
  }

  void setDescription(String? v) {
    updateState((s) => s.copyWith(description: v));
  }

  void setAddress(String? v) {
    updateState((s) => s.copyWith(address: v));
  }

  Future<void> deleteLocation() => _dbOps.deleteLocation(_loadedLocation!.id);

  // ----- StateManagementMixin overrides --------------------------------------------------

  @override
  bool isValidState() {
    final form = formKey.currentState;
    if (form != null && !form.validate()) return false;

    return true;
  }

  @override
  Future<void> onSaveState(EditLocationState data) async {
    // A) Compute the baseline set of GUIDs (from the original state before edits)
    final prevGuids = originalState.images.ids
        .whereType<PersistedImageIdentifier>()
        .map((g) => g.guid)
        .toSet();

    // B) Persist any temp images -> GUIDs (order preserved).
    //    Also converts identifiers in the image mixin in-place from Temp -> Guid.
    final guids = await persistImageGuids(deleteTempOnSuccess: true);

    // C) Build and persist your domain model
    EditLocationState s = currentState;
    final model = Location(
      id: _loadedLocation?.id,
      name: s.name.trim(),
      description: s.description.trim().isEmpty ? null : s.description.trim(),
      address: s.address.trim().isEmpty ? null : s.address.trim(),
      imageGuids: guids,
    );
    await _data.upsertLocation(model);

    // D) Best-effort orphan cleanup: delete any previously-persisted images
    //    that were removed during editing.
    final removed = prevGuids.difference(guids.toSet()).toList();
    if (removed.isNotEmpty) {
      await _imageStore.deleteImages(removed);
    }
  }

  // ----- GeolocateMixin overrides --------------------------------------------------
  @protected
  @override
  void onAcquiredAddress(String address) {
    updateState((s) => s.copyWith(address: address), notify: false);

    addressController.silentUpdate(address);
  }
}
