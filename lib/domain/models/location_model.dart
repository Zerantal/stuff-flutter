// lib/domain/models/location_model.dart
import 'package:meta/meta.dart';

import '../../core/models/base_model.dart';

class Location extends BaseModel<Location> {
  final String name;
  final String? description;
  final String? address;
  final List<String> imageGuids;

  Location({
    super.id,
    super.createdAt,
    super.updatedAt,

    // Domain fields:
    required this.name,
    this.description,
    this.address,
    List<String> imageGuids = const [],
  }) : imageGuids = List.unmodifiable(List<String>.from(imageGuids));

  /// Domain-only copyWith: callers never touch id/createdAt/updatedAt.
  Location copyWith({
    String? name,
    String? description,
    String? address,
    List<String>? imageGuids,
  }) {
    return Location(
      id: id, // unchanged
      createdAt: createdAt, // unchanged
      updatedAt: updatedAt, // unchanged (infra may bump via withTouched())
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      imageGuids: imageGuids ?? this.imageGuids,
    );
  }

  /// Infra-only: allow BaseModel to bump updatedAt.
  @protected
  @override
  Location copyWithUpdatedAt(DateTime nextUpdatedAt) {
    return Location(
      id: id,
      createdAt: createdAt,
      updatedAt: nextUpdatedAt,
      name: name,
      description: description,
      address: address,
      imageGuids: imageGuids,
    );
  }
}
