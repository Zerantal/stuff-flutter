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

// ---- Container ----
extension ContainerRowMapper on ContainerRow {
  Container toDomain() => Container(
    id: id,
    roomId: roomId,
    parentContainerId: parentContainerId,
    name: name,
    description: description,
    imageGuids: imageGuidsJson,
    positionIndex: positionIndex,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension ContainerToCompanion on Container {
  ContainersCompanion toCompanion() => ContainersCompanion(
    id: Value(id),
    roomId: Value(roomId),
    parentContainerId: Value(parentContainerId),
    name: Value(name),
    description: Value(description),
    imageGuidsJson: Value(imageGuids.toList()),
    positionIndex: Value(positionIndex),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

// ---- Item ----
extension ItemRowMapper on ItemRow {
  Item toDomain() => Item(
    id: id,
    roomId: roomId,
    containerId: containerId,
    name: name,
    description: description,
    attrs: attrsJson, // via JsonMapConverter
    imageGuids: imageGuidsJson, // via StringListConverter
    positionIndex: positionIndex,
    isArchived: isArchived,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension ItemToCompanion on Item {
  ItemsCompanion toCompanion() => ItemsCompanion(
    id: Value(id),
    roomId: Value(roomId),
    containerId: Value(containerId),
    name: Value(name),
    description: Value(description),
    attrsJson: Value(attrs),
    imageGuidsJson: Value(imageGuids.toList()),
    positionIndex: Value(positionIndex),
    isArchived: Value(isArchived),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}
