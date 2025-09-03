// lib/features/room/state/edit_room_state.dart
//
// Immutable state for the Edit Room screen.

import '../../shared/state/image_set.dart';

class EditRoomState {
  final String name;
  final String description;

  final ImageSet images;

  EditRoomState({this.name = '', this.description = '', ImageSet? images})
    : images = images ?? ImageSet.empty();

  EditRoomState copyWith({String? name, String? description, ImageSet? images}) {
    return EditRoomState(
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditRoomState &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          images == other.images;

  @override
  int get hashCode => Object.hash(name, description, images);
}
