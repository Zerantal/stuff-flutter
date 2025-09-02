// lib/features/room/state/edit_room_state.dart
//
// Immutable state for the Edit Room screen.

import 'package:collection/collection.dart';

import '../../../core/image_identifier.dart';
import '../../../shared/image/image_ref.dart';

class EditRoomState {
  final String name;
  final String description;

  /// UI-agnostic images the page can render directly.
  final List<ImageRef> images;

  /// Identity of each image (persisted or temp).
  /// Used only for equality/dirty tracking.
  final List<ImageIdentifier> imageIds;

  EditRoomState({
    this.name = '',
    this.description = '',
    List<ImageRef> images = const [],
    List<ImageIdentifier> imageIds = const [],
  }) : images = List<ImageRef>.unmodifiable(List<ImageRef>.from(images)),
       imageIds = List<ImageIdentifier>.unmodifiable(List<ImageIdentifier>.from(imageIds));

  EditRoomState copyWith({
    String? name,
    String? description,
    List<ImageRef>? images,
    List<ImageIdentifier>? imageIds,
  }) {
    return EditRoomState(
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
      imageIds: imageIds ?? this.imageIds,
    );
  }

  static const _idsEq = ListEquality<ImageIdentifier>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditRoomState &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          _idsEq.equals(imageIds, other.imageIds);

  @override
  int get hashCode => Object.hash(name, description, _idsEq.hash(imageIds));
}
