// lib/domain/models/room_model.dart
import 'dart:collection';

import '../../core/models/base_model.dart';

class Room extends BaseModel {
  String locationId; // Foreign key to Location

  String name;

  String? description;

  final UnmodifiableListView<String> imageGuids;

  Room({
    super.id,
    required this.locationId,
    required this.name,
    this.description,
    List<String>? imageGuids,
    super.createdAt,
    super.updatedAt,
  }) : imageGuids = UnmodifiableListView(imageGuids ?? []);

  Room copyWith({String? locationId, String? name, String? description, List<String>? imageGuids}) {
    // Prepare new list: clone provided or existing
    final newImages = imageGuids != null
        ? UnmodifiableListView(List<String>.from(imageGuids))
        : UnmodifiableListView(List<String>.from(this.imageGuids));

    return Room(
      id: id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageGuids: newImages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
