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
