part of 'database.dart';

// ---- Location ----
extension LocationRowMapper on LocationRow {
  Location toDomain() => Location(
    id: id,
    name: name,
    description: description,
    address: address,
    imageGuids: imageGuidsJson, // already List<String> via converter
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension LocationToCompanion on Location {
  LocationsCompanion toCompanion() => LocationsCompanion(
    id: Value(id),
    name: Value(name),
    description: Value(description),
    address: Value(address),
    imageGuidsJson: Value(imageGuids.toList()),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

// ---- Room ----
extension RoomRowMapper on RoomRow {
  Room toDomain() => Room(
    id: id,
    locationId: locationId,
    name: name,
    description: description,
    imageGuids: imageGuidsJson,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension RoomToCompanion on Room {
  RoomsCompanion toCompanion() => RoomsCompanion(
    id: Value(id),
    locationId: Value(locationId),
    name: Value(name),
    description: Value(description),
    imageGuidsJson: Value(imageGuids.toList()),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}
