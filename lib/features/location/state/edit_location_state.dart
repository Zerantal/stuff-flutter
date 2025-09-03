// lib/features/location/state/edit_location_state.dart
//
// Immutable state for the Edit Location screen.

import 'package:collection/collection.dart';

import '../../../core/image_identifier.dart';
import '../../../shared/image/image_ref.dart';
import '../../shared/state/image_set.dart';

class EditLocationState {
  final String name;
  final String description;
  final String address;

  final ImageSet images;

  EditLocationState({
    this.name = '',
    this.description = '',
    this.address = '',
    ImageSet? images,
  }) : images = images ?? ImageSet.empty();


  EditLocationState copyWith({
    String? name,
    String? description,
    String? address,
    ImageSet? images,
  }) {
    return EditLocationState(
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      images: images ?? this.images,
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
          images == other.images;

  @override
  int get hashCode => Object.hash(name, description, address, images);
}
