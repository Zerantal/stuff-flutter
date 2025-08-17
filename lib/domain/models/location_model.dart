// lib/domain/models/location_model.dart
import 'dart:collection';

import '../../core/models/base_model.dart';

class Location extends BaseModel {
  final String name;

  final String? description;

  final String? address;

  final UnmodifiableListView<String> imageGuids;

  Location({
    super.id,
    required this.name,
    this.description,
    this.address,
    List<String>? imageGuids,
    super.createdAt,
    super.updatedAt,
  }) : imageGuids = UnmodifiableListView(imageGuids ?? []);

  /// Creates a copy of this [Location] with the given fields updated.
  ///
  /// - `name`, `description`, `address` override those fields if non-null.
  /// - `images` replaces the entire list if non-null; pass `[]` to clear.
  Location copyWith({
    String? name,
    String? description,
    String? address,
    List<String>? imageGuids,
  }) {
    // Prepare new list: clone provided or existing
    final newImages = imageGuids != null
        ? UnmodifiableListView(List<String>.from(imageGuids))
        : UnmodifiableListView(List<String>.from(this.imageGuids));

    return Location(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      imageGuids: newImages,
    );
  }
}
