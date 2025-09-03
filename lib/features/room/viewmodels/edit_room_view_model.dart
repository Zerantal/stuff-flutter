// lib/features/room/viewmodels/edit_room_view_model.dart
import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/image_identifier.dart';
import '../../../core/util/string_util.dart';
import '../../../domain/models/room_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../services/ops/db_ops.dart';
import '../../../shared/forms/suppressible_text_editing_controller.dart';
import '../../../shared/image/image_ref.dart';
import '../../shared/edit/image_picking_mixin.dart';
import '../../shared/edit/state_management_mixin.dart';
import '../../shared/state/image_set.dart';
import '../state/edit_room_state.dart';

// final _log = Logger('EditRoomViewModel');

class EditRoomViewModel extends ChangeNotifier
    with StateManagementMixin<EditRoomState>, ImageEditingMixin {
  EditRoomViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
    required ITemporaryFileService tempFileService,
    required this.locationId,
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

  static EditRoomViewModel forEdit(
    BuildContext ctx, {
    required String locationId,
    required String roomId,
  }) {
    final vm = EditRoomViewModel(
      dataService: ctx.read<IDataService>(),
      imageDataService: ctx.read<IImageDataService>(),
      tempFileService: ctx.read<ITemporaryFileService>(),
      locationId: locationId,
    );
    scheduleMicrotask(() => vm.initForEdit(roomId));
    return vm;
  }

  static EditRoomViewModel forNew(BuildContext ctx, {required String locationId}) {
    final vm = EditRoomViewModel(
      dataService: ctx.read<IDataService>(),
      imageDataService: ctx.read<IImageDataService>(),
      tempFileService: ctx.read<ITemporaryFileService>(),
      locationId: locationId,
    );
    scheduleMicrotask(() => vm.initForNew());
    return vm;
  }
  // ----------------------------------------------------------------------------------

  final IDataService _data;
  final IImageDataService _imageStore;
  final String locationId;
  final DbOps _dbOps;

  final uuid = const Uuid();

  // Form
  final formKey = GlobalKey<FormState>();
  final nameController = SuppressibleTextEditingController();
  final descriptionController = SuppressibleTextEditingController();

  Room? _loadedRoom;

  late bool _isNewRoom;
  bool get isNewRoom => _isNewRoom;

  // Image list revision counter (cheap O(1) change signal)
  int _imageListRevision = 0;
  int get imageListRevision => _imageListRevision;

  // ----- Lifecycle ----------------------------------------------------------

  Future<void> initForEdit(String roomId) async {
    _isNewRoom = false;

    await initialiseStateAsync(() async {
      _loadedRoom = await _data.getRoomById(roomId);

      if (_loadedRoom != null) {
        nameController.text = _loadedRoom!.name;
        descriptionController.text = _loadedRoom!.description ?? '';

        return EditRoomState(
          name: _loadedRoom!.name,
          description: _loadedRoom!.description ?? '',
          images: ImageSet.fromGuids(_imageStore, _loadedRoom!.imageGuids),
        );
      }
      throw Exception('Room not found');
    });

    if (!isInitialised) return;

    // create session for storing temp files
    final String sessionLabel = concatenateFirstTenChars(['edit_room', locationId, roomId]);
    await startImageSession(sessionLabel);
    seedExistingImages(currentState.images, notify: true);

    initTextControllers();
  }

  Future<void> initForNew() async {
    _isNewRoom = true;

    initialiseState(EditRoomState());

    // create session for storing temp files
    final String sessionLabel = concatenateFirstTenChars(['add_room', locationId, (uuid.v4())]);
    await startImageSession(sessionLabel);

    initTextControllers();
  }

  Future<void> retryInitForEdit(String roomId) async {
    clearInitialLoadError();
    await initForEdit(roomId);
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

  Future<void> deleteRoom() => _dbOps.deleteRoom(_loadedRoom!.id);

  // ----- StateManagementMixin overrides --------------------------------------------------

  @override
  bool isValidState() {
    final form = formKey.currentState;
    if (form != null && !form.validate()) return false;

    return true;
  }

  @override
  Future<void> onSaveState(EditRoomState data) async {
    // A) Compute the baseline set of GUIDs (from the original state before edits)
    final prevGuids = originalState.images.ids
        .whereType<PersistedImageIdentifier>()
        .map((g) => g.guid)
        .toSet();

    // B) Persist any temp images -> GUIDs (order preserved).
    //    Also converts identifiers in the image mixin in-place from Temp -> Guid.
    final guids = await persistImageGuids(deleteTempOnSuccess: true);

    // C) Build and persist your domain model
    EditRoomState s = currentState;
    final model = Room(
      id: _loadedRoom?.id,
      locationId: locationId,
      name: s.name.trim(),
      description: s.description.trim().isEmpty ? null : s.description.trim(),
      imageGuids: guids,
    );
    await _data.upsertRoom(model);

    // D) Best-effort orphan cleanup: delete any previously-persisted images
    //    that were removed during editing.
    final removed = prevGuids.difference(guids.toSet()).toList();
    if (removed.isNotEmpty) {
      await _imageStore.deleteImages(removed);
    }
  }
}
