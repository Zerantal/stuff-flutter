// lib/domain/models/room_model.dart
import 'package:meta/meta.dart';

import '../../core/models/base_model.dart';

class Room extends BaseModel<Room> {
  String locationId; // Foreign key to Location
  String name;
  String? description;
  final List<String> imageGuids;

  Room({
    super.id,
    super.createdAt,
    super.updatedAt,

    required this.locationId,
    required this.name,
    this.description,
    List<String> imageGuids = const [],
  }) : imageGuids = List.unmodifiable(List<String>.from(imageGuids));

  Room copyWith({String? locationId, String? name, String? description, List<String>? imageGuids}) {
    return Room(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageGuids: imageGuids ?? this.imageGuids,
    );
  }

  @protected
  @override
  Room copyWithUpdatedAt(DateTime nextUpdatedAt) {
    return Room(
      id: id,
      createdAt: createdAt,
      updatedAt: nextUpdatedAt,
      locationId: locationId,
      name: name,
      description: description,
      imageGuids: imageGuids,
    );
  }
}
