// lib/features/room/viewmodels/edit_room_view_model.dart
import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/image_identifier.dart';
import '../../../core/util/string_util.dart';
import '../../../domain/models/item_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../services/ops/db_ops.dart';
import '../../../shared/forms/suppressible_text_editing_controller.dart';
import '../../shared/edit/image_picking_mixin.dart';
import '../../shared/edit/state_management_mixin.dart';
import '../../shared/state/image_set.dart';
import '../state/item_details_state.dart';

// final _log = Logger('EditRoomViewModel');

enum _InitMode { none, item, newItem }

class ItemDetailsViewModel extends ChangeNotifier
    with StateManagementMixin<ItemDetailsState>, ImageEditingMixin {
  ItemDetailsViewModel({
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

  _InitMode _initMode = _InitMode.none;

  final IDataService _data;
  final IImageDataService _imageStore;
  final DbOps _dbOps;
  String? itemId;
  String? roomId;
  String? containerId;

  // Form
  final formKey = GlobalKey<FormState>();
  final nameController = SuppressibleTextEditingController();
  final descriptionController = SuppressibleTextEditingController();

  Item? _loadedItem;

  bool _isNewItem = false;
  bool get isNewItem => _isNewItem;

  // Image list revision counter (cheap O(1) change signal)
  int _imageListRevision = 0;
  int get imageListRevision => _imageListRevision;

  // ------------------ Context-aware convenience factories --------------------
  static ItemDetailsViewModel forItem(
    BuildContext ctx, {
    required String itemId,
    required bool editable,
  }) {
    final vm = ItemDetailsViewModel(
      dataService: ctx.read<IDataService>(),
      imageDataService: ctx.read<IImageDataService>(),
      tempFileService: ctx.read<ITemporaryFileService>(),
    );
    scheduleMicrotask(() => vm._initWithItem(itemId, editable: editable));
    return vm;
  }

  static ItemDetailsViewModel forNew(BuildContext ctx, {String? roomId, String? containerId}) {
    final vm = ItemDetailsViewModel(
      dataService: ctx.read<IDataService>(),
      imageDataService: ctx.read<IImageDataService>(),
      tempFileService: ctx.read<ITemporaryFileService>(),
    );
    scheduleMicrotask(() => vm._initForNew(roomId: roomId, containerId: containerId));
    return vm;
  }

  // ----- Lifecycle ----------------------------------------------------------
  Future<void> _initWithItem(String itemId, {required bool editable}) async {
    _isNewItem = false;
    isEditable = editable;
    this.itemId = itemId;
    _initMode = _InitMode.item;

    await initialiseStateAsync(() async {
      _loadedItem = await _data.getItemById(itemId);

      if (_loadedItem == null) throw Exception('Item not found');

      nameController.text = _loadedItem!.name;
      descriptionController.text = _loadedItem!.description ?? '';

      roomId = _loadedItem!.roomId;

      return ItemDetailsState(
        name: _loadedItem!.name,
        description: _loadedItem!.description ?? '',
        images: ImageSet.fromGuids(_imageStore, _loadedItem!.imageGuids),
      );
    });

    if (!isInitialised) return;

    // upon successful init, roomId will be set
    assert(roomId != null);

    if (isEditable) {
      // create session for storing temp files
      final String sessionLabel = concatenateFirstTenChars(['edit_item', itemId]);
      await startImageSession(sessionLabel);
      seedExistingImages(currentState.images, notify: true);

      _initTextControllers();
    }
  }

  Future<void> _initForNew({String? roomId, String? containerId}) async {
    assert(
      (roomId == null) ^ (containerId == null),
      'Must provide either roomId or parentContainerId (not both)',
    );

    this.roomId = roomId;
    this.containerId = containerId;
    _initMode = _InitMode.newItem;

    if (isInitialised) {
      throw StateError('ItemDetailsViewModel is already initialised.');
    }

    late String id;

    Future<void> setRoomId() async {
      if (roomId != null) {
        this.roomId = roomId;
        return;
      }

      this.containerId = containerId;
      final container = await _data.getContainerById(containerId!);
      if (container != null) {
        this.roomId = container.roomId;
      } else {
        throw Exception('Container not found');
      }
    }

    await initialiseStateAsync(() async {
      await setRoomId();

      _isNewItem = true;

      return ItemDetailsState();
    });

    if (!isInitialised) return;

    // upon successful init, roomId will be set
    assert(roomId != null);

    id = this.containerId ?? this.roomId!;
    final String sessionLabel = concatenateFirstTenChars(['add_item', id, (const Uuid().v4())]);
    await startImageSession(sessionLabel);

    _initTextControllers();
  }

  Future<void> retryInit() async {
    clearInitialLoadError();

    switch (_initMode) {
      case _InitMode.item:
        if (itemId == null) {
          throw StateError('retryInit called in item mode without an itemId');
        }
        await _initWithItem(itemId!, editable: isEditable);
        break;
      case _InitMode.newItem:
        await _initForNew(roomId: roomId, containerId: containerId);
        break;
      case _InitMode.none:
        throw StateError('retryInit called before initialization');
    }
  }

  void _initTextControllers() {
    nameController.addListener(() => setName(nameController.text));
    descriptionController.addListener(() => setDescription(descriptionController.text));
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    disposeImageSession();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Field setters
  void setName(String v) => updateState((s) => s.copyWith(name: v));
  void setDescription(String? v) => updateState((s) => s.copyWith(description: v));

  Future<void> deleteItem() => _dbOps.deleteItem(_loadedItem!.id);

  // ----- StateManagementMixin overrides --------------------------------------------------

  @override
  bool isValidState() {
    final form = formKey.currentState;
    return form == null || form.validate();
  }

  @override
  @protected
  Future<void> onSaveState(ItemDetailsState data) async {
    // A) Compute the baseline set of GUIDs (from the original state before edits)
    final prevGuids = originalState.images.ids
        .whereType<PersistedImageIdentifier>()
        .map((g) => g.guid)
        .toSet();

    // B) Persist any temp images -> GUIDs (order preserved).
    //    Also converts identifiers in the image mixin in-place from Temp -> Guid.
    final guids = await persistImageGuids(deleteTempOnSuccess: true);

    // C) Build and persist your domain model
    ItemDetailsState s = currentState;
    final model = Item(
      id: _loadedItem?.id,
      roomId: roomId!,
      containerId: _loadedItem?.containerId ?? containerId,
      name: s.name.trim(),
      description: s.description.trim().isEmpty ? null : s.description.trim(),
      imageGuids: guids,
    );
    await _data.upsertItem(model);

    // D) Best-effort orphan cleanup: delete any previously-persisted images
    //    that were removed during editing.
    final removed = prevGuids.difference(guids.toSet()).toList();
    if (removed.isNotEmpty) {
      await _imageStore.deleteImages(removed);
    }
  }

  // In response to editability change
  @override
  void onChangeIsEditableState(bool isEditable) async {
    if (isEditable) {
      // upgrade: attach controllers + start temp session
      final String sessionLabel = concatenateFirstTenChars(['edit_item', itemId ?? '']);
      await startImageSession(sessionLabel);
      seedExistingImages(currentState.images, notify: true);
      _initTextControllers();
    } else {
      // downgrade: remove controllers + clear temp session
      nameController.clearListeners();
      descriptionController.clearListeners();
      disposeImageSession();
    }

    notifyListeners();
  }
}
