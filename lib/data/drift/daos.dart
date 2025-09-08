// lib/data/drift/daos.dart
// coverage:ignore-file

part of 'database.dart';

@DriftAccessor(tables: [Locations, Rooms])
class LocationDao extends DatabaseAccessor<AppDatabase> with _$LocationDaoMixin {
  LocationDao(super.db);

  Stream<List<Location>> watchAll() => (select(
    locations,
  )).watch().map((rows) => rows.map((r) => r.toDomain()).toList(growable: false));

  Future<List<Location>> getAll() async =>
      (await select(locations).get()).map((r) => r.toDomain()).toList(growable: false);

  Future<Location?> getById(String id) async {
    final row = await (select(locations)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<Location> upsert(Location loc) async {
    await into(locations).insertOnConflictUpdate(loc.toCompanion());
    return loc;
  }

  Future<void> deleteById(String id) => (delete(locations)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Rooms, Locations])
class RoomDao extends DatabaseAccessor<AppDatabase> with _$RoomDaoMixin {
  RoomDao(super.db);

  Stream<List<Room>> watchFor(String locationId) =>
      (select(rooms)..where((r) => r.locationId.equals(locationId))).watch().map(
        (rows) => rows.map((r) => r.toDomain()).toList(growable: false),
      );

  Future<List<Room>> getFor(String locationId) async =>
      (await (select(rooms)..where((r) => r.locationId.equals(locationId))).get())
          .map((r) => r.toDomain())
          .toList(growable: false);

  Future<Room?> getById(String id) async {
    final row = await (select(rooms)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<Room> upsert(Room room) async {
    await into(rooms).insertOnConflictUpdate(room.toCompanion());
    return room;
  }

  Future<void> deleteById(String id) => (delete(rooms)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Containers, Rooms])
class ContainerDao extends DatabaseAccessor<AppDatabase> with _$ContainerDaoMixin {
  ContainerDao(super.db);

  // Top-level containers in a room
  Stream<List<Container>> watchTopLevelByRoom(String roomId) =>
      (select(containers)
            ..where((t) => t.roomId.equals(roomId) & t.parentContainerId.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.positionIndex, mode: OrderingMode.asc)]))
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList(growable: false));

  // Children of a container
  Stream<List<Container>> watchChildren(String containerId) =>
      (select(containers)
            ..where((t) => t.parentContainerId.equals(containerId))
            ..orderBy([(t) => OrderingTerm(expression: t.positionIndex, mode: OrderingMode.asc)]))
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList(growable: false));

  Future<Container?> getById(String id) async {
    final row = await (select(containers)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<Container> upsert(Container c) async {
    await into(containers).insertOnConflictUpdate(c.toCompanion());
    return c;
  }

  Future<void> deleteById(String id) => (delete(containers)..where((t) => t.id.equals(id))).go();

  // Containers for an entire location (top-level only)
  Stream<List<Container>> watchTopLevelByLocation(String locationId) {
    final j = select(containers).join([innerJoin(rooms, rooms.id.equalsExp(containers.roomId))]);

    j.where(rooms.locationId.equals(locationId) & containers.parentContainerId.isNull());

    return j.watch().map((rows) {
      return rows
          .map((r) => r.readTable(containers))
          .map((row) => row.toDomain()) // your mapper
          .toList(growable: false);
    });
  }

  Stream<List<Container>> watchAllContainers() {
    final q = select(containers)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
      ]);
    return q.watch().map((rows) {
      return rows.map((row) => row.toDomain()).toList(growable: false);
    });
  }
}

@DriftAccessor(tables: [Items, Rooms])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(super.db);

  // Items directly in the room (no container)
  Stream<List<Item>> watchInRoom(String roomId) =>
      (select(items)
            ..where(
              (t) => t.roomId.equals(roomId) & t.containerId.isNull() & t.isArchived.equals(false),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.positionIndex, mode: OrderingMode.asc)]))
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList(growable: false));

  // Items in a container
  Stream<List<Item>> watchInContainer(String containerId) =>
      (select(items)
            ..where((t) => t.containerId.equals(containerId) & t.isArchived.equals(false))
            ..orderBy([(t) => OrderingTerm(expression: t.positionIndex, mode: OrderingMode.asc)]))
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList(growable: false));

  Future<Item?> getById(String id) async {
    final row = await (select(items)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<Item> upsert(Item item) async {
    await into(items).insertOnConflictUpdate(item.toCompanion());
    return item;
  }

  Future<void> deleteById(String id) => (delete(items)..where((t) => t.id.equals(id))).go();

  Future<void> setArchived(String id, bool archived, {DateTime? updatedAt}) {
    final ts = updatedAt ?? DateTime.now();
    return (update(items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(isArchived: Value(archived), updatedAt: Value(ts)),
    );
  }

  // Items in an entire location that are *directly in rooms* (not nested)
  Stream<List<Item>> watchInLocation(String locationId) {
    final j = select(items).join([innerJoin(rooms, rooms.id.equalsExp(items.roomId))]);

    j.where(
      rooms.locationId.equals(locationId) &
          items.containerId.isNull() &
          items.isArchived.equals(false),
    );

    return j.watch().map((rows) {
      return rows
          .map((r) => r.readTable(items))
          .map((row) => row.toDomain())
          .toList(growable: false);
    });
  }

  Stream<List<Item>> watchAllItems() {
    final q = select(items)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
      ]);
    return q.watch().map((rows) {
      return rows.map((row) => row.toDomain()).toList(growable: false);
    });
  }
}
