// lib/models/room_model.dart
import 'package:hive_ce/hive.dart';

import '../core/models/base_model.dart';

part 'room_model.g.dart'; // Ensure you run build_runner after changes

@HiveType(typeId: 1)
class Room extends BaseModel {
  @HiveField(3)
  String locationId; // Foreign key to Location

  @HiveField(4)
  String name;

  @HiveField(5)
  String? description;

  @HiveField(6)
  List<String>? imageGuids;

  Room({
    super.id,
    required this.locationId,
    required this.name,
    this.description,
    List<String>? imageGuids,
    super.createdAt,
    super.updatedAt,
  }) : imageGuids = imageGuids ?? [];
}
