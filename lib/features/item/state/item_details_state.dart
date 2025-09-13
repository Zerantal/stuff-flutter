// lib/features/item/state/item_details_state.dart
//
// Immutable state for the item details screen.

import '../../shared/state/image_set.dart';

class ItemDetailsState {
  final String name;
  final String description;

  final ImageSet images;

  ItemDetailsState({this.name = '', this.description = '', ImageSet? images})
    : images = images ?? ImageSet.empty();

  ItemDetailsState copyWith({String? name, String? description, ImageSet? images}) {
    return ItemDetailsState(
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemDetailsState &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          images == other.images;

  @override
  int get hashCode => Object.hash(name, description, images);
}
