// lib/features/container/viewmodels/edit_container_view_model.dart
import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/image_identifier.dart';
import '../../../core/util/string_util.dart';
import '../../../domain/models/container_model.dart' as domain;
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../services/ops/db_ops.dart';
import '../../../shared/forms/suppressible_text_editing_controller.dart';
import '../../shared/edit/image_picking_mixin.dart';
import '../../shared/edit/state_management_mixin.dart';
import '../../shared/state/image_set.dart';
import '../state/edit_container_state.dart';

// final _log = Logger('EditContainerViewModel');

class EditContainerViewModel extends ChangeNotifier
    with StateManagementMixin<EditContainerState>, ImageEditingMixin {
  EditContainerViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
    required ITemporaryFileService tempFileService,
  }) : _data = dataService,
       _imageStore = imageDataService,
       _dbOps = DbOps(dataService, imageDataService) {
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

  static EditContainerViewModel forEdit(BuildContext ctx, {required String containerId}) {
    final vm = EditContainerViewModel(
      dataService: ctx.read<IDataService>(),
      imageDataService: ctx.read<IImageDataService>(),
      tempFileService: ctx.read<ITemporaryFileService>(),
    );
    scheduleMicrotask(() => vm.initForEdit(containerId));
    return vm;
  }

  static EditContainerViewModel forNew(
    BuildContext ctx, {
    String? roomId,
    String? parentContainerId,
  }) {
    assert(
      (roomId == null) ^ (parentContainerId == null),
      'Must provide either roomId or parentContainerId (not both)',
    );
    final vm = EditContainerViewModel(
      dataService: ctx.read<IDataService>(),
      imageDataService: ctx.read<IImageDataService>(),
      tempFileService: ctx.read<ITemporaryFileService>(),
    );
    scheduleMicrotask(() => vm._initForNew(roomId: roomId, parentContainerId: parentContainerId));
    return vm;
  }

  // ----------------------------------------------------------------------------------

  final IDataService _data;
  final IImageDataService _imageStore;
  String? parentContainerId; // if adding new container to container
  late String roomId; // Must be set if adding new to room or container
  String? containerId; // if editing existing container
  final DbOps _dbOps;

  final uuid = const Uuid();

  // Form
  final formKey = GlobalKey<FormState>();
  final nameController = SuppressibleTextEditingController();
  final descriptionController = SuppressibleTextEditingController();

  domain.Container? _loadedContainer;

  late bool _isNewContainer;
  bool get isNewContainer => _isNewContainer;

  // Image list revision counter (cheap O(1) change signal)
  int _imageListRevision = 0;

  int get imageListRevision => _imageListRevision;

  // ----- Lifecycle ----------------------------------------------------------

  Future<void> initForEdit(String containerId) async {
    _isNewContainer = false;

    await initialiseStateAsync(() async {
      _loadedContainer = await _data.getContainerById(containerId);

      if (_loadedContainer != null) {
        nameController.text = _loadedContainer!.name;
        descriptionController.text = _loadedContainer!.description ?? '';

        return EditContainerState(
          name: _loadedContainer!.name,
          description: _loadedContainer!.description ?? '',
          images: ImageSet.fromGuids(_imageStore, _loadedContainer!.imageGuids),
        );
      }
      throw Exception('Container not found');
    });

    if (!isInitialised) return;

    // create session for storing temp files
    final String sessionLabel = concatenateFirstTenChars(['edit_container', containerId]);
    await startImageSession(sessionLabel);
    seedExistingImages(currentState.images, notify: true);

    initTextControllers();
  }

  Future<void> _initForNew({String? roomId, String? parentContainerId}) async {
    late String id;

    if (roomId != null) {
      this.roomId = roomId;
      id = roomId;
    } else {
      this.parentContainerId = parentContainerId;
      id = parentContainerId!;
      // retrieve parent container and assign roomId
      await initialiseStateAsync(() async {
        final parentContainer = await _data.getContainerById(parentContainerId);

        if (parentContainer != null) {
          this.roomId = parentContainer.roomId;
        }
        throw Exception('Container not found');
      });
    }

    _isNewContainer = true;

    initialiseState(EditContainerState());

    // create session for storing temp files
    final String sessionLabel = concatenateFirstTenChars(['add_container', id, (uuid.v4())]);
    await startImageSession(sessionLabel);

    initTextControllers();
  }

  Future<void> retryInitForEdit(String containerId) async {
    clearInitialLoadError();
    await initForEdit(containerId);
  }

  void initTextControllers() {
    nameController.addListener(() => setName(nameController.text));
    descriptionController.addListener(() => setDescription(descriptionController.text));
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
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

  Future<void> deleteContainer() => _dbOps.deleteContainer(_loadedContainer!.id);

  // ----- StateManagementMixin overrides --------------------------------------------------

  @override
  bool isValidState() {
    final form = formKey.currentState;
    if (form != null && !form.validate()) return false;

    return true;
  }

  @override
  Future<void> onSaveState(EditContainerState data) async {
    // A) Compute the baseline set of GUIDs (from the original state before edits)
    final prevGuids = originalState.images.ids
        .whereType<PersistedImageIdentifier>()
        .map((g) => g.guid)
        .toSet();

    // B) Persist any temp images -> GUIDs (order preserved).
    //    Also converts identifiers in the image mixin in-place from Temp -> Guid.
    final guids = await persistImageGuids(deleteTempOnSuccess: true);

    // C) Build and persist your domain model
    EditContainerState s = currentState;
    final model = domain.Container(
      id: _loadedContainer?.id,
      roomId: _isNewContainer ? roomId : _loadedContainer!.roomId,
      parentContainerId: _isNewContainer ? parentContainerId : _loadedContainer?.parentContainerId,
      name: s.name.trim(),
      description: s.description.trim().isEmpty ? null : s.description.trim(),
      imageGuids: guids,
    );
    await _data.upsertContainer(model);

    // D) Best-effort orphan cleanup: delete any previously-persisted images
    //    that were removed during editing.
    final removed = prevGuids.difference(guids.toSet()).toList();
    if (removed.isNotEmpty) {
      await _imageStore.deleteImages(removed);
    }
  }
}
