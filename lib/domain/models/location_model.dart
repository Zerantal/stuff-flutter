// lib/domain/models/location_model.dart
import 'dart:collection';

import 'package:hive_ce/hive.dart';

import '../../core/models/base_model.dart';

part 'location_model.g.dart';

@HiveType(typeId: 0)
class Location extends BaseModel {
  @HiveField(3)
  final String name;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final String? address;

  @HiveField(6)
  final UnmodifiableListView<String> images;

  Location({
    super.id,
    required this.name,
    this.description,
    this.address,
    List<String>? images,
    super.createdAt,
    super.updatedAt,
  }) : images = UnmodifiableListView(images ?? []);

  /// Creates a copy of this [Location] with the given fields updated.
  ///
  /// - `name`, `description`, `address` override those fields if non-null.
  /// - `images` replaces the entire list if non-null; pass `[]` to clear.
  Location copyWith({String? name, String? description, String? address, List<String>? images}) {
    // Prepare new list: clone provided or existing
    final newImages = images != null
        ? UnmodifiableListView(List<String>.from(images))
        : UnmodifiableListView(List<String>.from(this.images));

    return Location(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      images: newImages,
    );
  }
}
