// lib/features/room/state/edit_room_state.dart
//
// Immutable state for the Edit Room screen.

import '../../../shared/image/image_ref.dart';

class EditRoomState {
  final String name;
  final String? description;

  /// UI-agnostic images the page can render directly.
  final List<ImageRef> images;

  final bool isNewRoom;
  final bool isSaving;
  final bool isPickingImage;
  final bool hasUnsavedChanges;
  final bool hasTempSession;

  const EditRoomState({
    required this.name,
    this.description,
    this.images = const [],
    required this.isNewRoom,
    this.isSaving = false,
    this.isPickingImage = false,
    this.hasUnsavedChanges = false,
    this.hasTempSession = false,
  });

  EditRoomState copyWith({
    String? name,
    String? description,
    String? address,
    List<ImageRef>? images,
    bool? isNewRoom,
    bool? isSaving,
    bool? isPickingImage,
    bool? hasUnsavedChanges,
    bool? hasTempSession,
  }) {
    return EditRoomState(
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
      isNewRoom: isNewRoom ?? this.isNewRoom,
      isSaving: isSaving ?? this.isSaving,
      isPickingImage: isPickingImage ?? this.isPickingImage,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      hasTempSession: hasTempSession ?? this.hasTempSession,
    );
  }
}
