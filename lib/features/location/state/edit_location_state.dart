// lib/features/location/state/edit_location_state.dart
//
// Immutable state for the Edit Location screen.

import 'package:collection/collection.dart';

import '../../../core/image_identifier.dart';
import '../../../shared/image/image_ref.dart';

class EditLocationState {
  final String name;
  final String description;
  final String address;

  /// UI-agnostic images the page can render directly.
  final List<ImageRef> images;

  /// Identity of each image (persisted or temp).
  /// Used only for equality/dirty tracking.
  final List<ImageIdentifier> imageIds;

  EditLocationState({
    this.name = '',
    this.description = '',
    this.address = '',
    List<ImageRef> images = const [],
    List<ImageIdentifier> imageIds = const [],
  }) : images = List<ImageRef>.unmodifiable(List<ImageRef>.from(images)),
       imageIds = List<ImageIdentifier>.unmodifiable(List<ImageIdentifier>.from(imageIds));

  EditLocationState copyWith({
    String? name,
    String? description,
    String? address,
    List<ImageRef>? images,
    List<ImageIdentifier>? imageIds,
  }) {
    return EditLocationState(
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      images: images ?? this.images,
      imageIds: imageIds ?? this.imageIds,
    );
  }

  static const _idsEq = ListEquality<ImageIdentifier>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditLocationState &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          address == other.address &&
          _idsEq.equals(imageIds, other.imageIds);

  @override
  int get hashCode => Object.hash(name, description, address, _idsEq.hash(imageIds));
}
