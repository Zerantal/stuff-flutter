// lib/features/room/viewmodels/edit_room_view_model.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../core/image_identifier.dart';
import '../../../domain/models/room_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../services/ops/db_ops.dart';
import '../../../shared/image/image_identifier_persistence.dart' as persist;
import '../../../shared/image/image_identifier_to_ref.dart' as id2ref;
import '../../../shared/image/image_ref.dart';
import '../state/edit_room_state.dart';

final _log = Logger('EditRoomViewModel');

class EditRoomViewModel extends ChangeNotifier {
  final IDataService _data;
  final IImageDataService _imageStore;
  final ITemporaryFileService _tmpFileSvc;
  final String locationId;
  final String? roomId; // null => create
  final DbOps _dbOps;

  bool _isInitialising = true;

  bool get isInitialising => _isInitialising;

  void setInitialising(bool v) {
    if (_isInitialising == v) return;
    _isInitialising = v;
    notifyListeners();
  }

  EditRoomViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
    required ITemporaryFileService tempFileService,
    required this.locationId,
    required this.roomId,
  }) : _data = dataService,
       _imageStore = imageDataService,
       _tmpFileSvc = tempFileService,
       _dbOps = DbOps(dataService, imageDataService);

  // Form
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // State
  EditRoomState _state = const EditRoomState(name: '', isNewRoom: true);

  EditRoomState get state => _state;

  // Expose bits the page expects
  bool get isNewRoom => _state.isNewRoom;
  bool get isSaving => _state.isSaving;
  bool get hasUnsavedChanges => _state.hasUnsavedChanges;
  bool get hasTempSession => _state.hasTempSession;

  // Images for UI:
  List<ImageRef> get images => _state.images;

  // Underlying identifiers we persist on save (kept in index-lockstep with _state.images)
  final List<ImageIdentifier> _imageIds = [];

  // Temp session for storing picked images
  TempSession? _tempSession;
  TempSession? get tempSession => _tempSession;

  Room? _loadedRoom;

  // ----- Lifecycle ----------------------------------------------------------
  Future<void> init() async {
    // editing an existing location, pull it from the DB
    if (roomId != null) {
      _loadedRoom = await _data.getRoomById(roomId!);

      if (_loadedRoom != null) {
        nameController.text = _loadedRoom!.name;
        descriptionController.text = _loadedRoom!.description ?? '';

        // Build identifiers from persisted GUIDs
        _imageIds
          ..clear()
          ..addAll(
            (_loadedRoom!.imageGuids)
                .where((g) => g.isNotEmpty)
                .map<PersistedImageIdentifier>((g) => PersistedImageIdentifier(g)),
          );

        // Map to ImageRef for UI
        final refs = await id2ref.toImageRefs(_imageIds, _imageStore);

        _state = _state.copyWith(
          name: _loadedRoom!.name,
          description: _loadedRoom!.description ?? '',
          images: refs,
          isNewRoom: false,
          hasUnsavedChanges: false,
        );
      }
    }

    final String sessionLabel;
    if (roomId != null) {
      sessionLabel = 'edit_room_$roomId!';
    } else {
      sessionLabel = 'add_room_$locationId';
    }

    _tempSession = await _tmpFileSvc.startSession(label: sessionLabel);
    _state = _state.copyWith(hasTempSession: true);

    // React to user typing to flip hasUnsavedChanges
    nameController.addListener(_onAnyFieldChanged);
    descriptionController.addListener(_onAnyFieldChanged);
    notifyListeners();

    setInitialising(false);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    _tempSession?.dispose();
    super.dispose();
  }

  Future<void> deleteRoom() => _dbOps.deleteRoom(roomId!);

  Future<bool> saveRoom() async {
    if (_state.isSaving) return false;

    // Validate the form if a validator is wired.
    final form = formKey.currentState;
    if (form != null && !form.validate()) return false;

    _state = _state.copyWith(isSaving: true);
    notifyListeners();

    try {
      // A) Remember what was previously persisted for this location
      final previousGuids = (_loadedRoom?.imageGuids ?? const <String>[]).toSet();

      // B) Persist any temp files → GUIDs (order preserved)
      final guids = await persist.persistTempImages(
        _imageIds,
        _imageStore,
        deleteTempOnSuccess: true, // cleanup
      );

      // C) Replace temp identifiers in the VM with their new GUIDs
      for (var i = 0; i < _imageIds.length; i++) {
        if (_imageIds[i] is TempImageIdentifier) {
          _imageIds[i] = PersistedImageIdentifier(guids[i]);
        }
      }

      // D) Build new model and save it
      late final Room toSave;
      if (_loadedRoom == null) {
        toSave = Room(
          locationId: locationId,
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          imageGuids: guids,
        );
      } else {
        toSave = _loadedRoom!.copyWith(
          name: nameController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          imageGuids: guids,
        );
      }

      // E) After the model is persisted, delete orphaned images
      final newGuids = guids.toSet();
      final toDelete = previousGuids.difference(newGuids);
      if (toDelete.isNotEmpty) {
        await _imageStore.deleteImages(toDelete); // best-effort
      }

      if (_loadedRoom == null) {
        await _data.addRoom(toSave);
        _loadedRoom = toSave; // locally consider it the current
        _state = _state.copyWith(isNewRoom: false);
      } else {
        await _data.updateRoom(toSave);
        _loadedRoom = toSave;
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

  // ----- Internal helpers ---------------------------------------------------

  // update form state data model
  void _onAnyFieldChanged() {
    final next = _state.copyWith(
      name: nameController.text,
      description: descriptionController.text,
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
}
