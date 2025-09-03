import '../../domain/models/location_model.dart';
import '../../domain/models/room_model.dart';
import '../contracts/data_service_interface.dart';
import '../../data/drift/database.dart';

class DriftDataService implements IDataService {
  DriftDataService(this.db) : locations = LocationDao(db), rooms = RoomDao(db);

  final AppDatabase db;
  final LocationDao locations;
  final RoomDao rooms;

  bool _disposed = false;
  void _ensureReady() {
    if (_disposed) throw StateError('DriftDataService has been disposed');
  }

  @override
  Future<void> init() async {
    // DB is ready on construction; nothing to do here
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await db.close();
  }

  // ------- Locations -------
  @override
  Stream<List<Location>> getLocationsStream() {
    _ensureReady();
    return locations.watchAll();
  }

  @override
  Future<List<Location>> getAllLocations() {
    _ensureReady();
    return locations.getAll();
  }

  @override
  Future<Location?> getLocationById(String id) {
    _ensureReady();
    return locations.getById(id);
  }

  @override
  Future<Location> addLocation(Location location) {
    _ensureReady();
    Location loc = location.withTouched();
    return locations.upsert(loc);
  }

  @override
  Future<Location> updateLocation(Location location) {
    _ensureReady();
    Location loc = location.withTouched();
    return locations.upsert(loc);
  }

  @override
  Future<Location> upsertLocation(Location location) {
    _ensureReady();
    Location loc = location.withTouched();
    return locations.upsert(loc);
  }

  @override
  Future<void> deleteLocation(String id) async {
    _ensureReady();
    // FK with ON DELETE CASCADE handles room deletions atomically
    await db.transaction(() async {
      await locations.deleteById(id);
    });
  }

  // ------- Rooms -------
  @override
  Stream<List<Room>> getRoomsStream(String locationId) {
    _ensureReady();
    return rooms.watchFor(locationId);
  }

  @override
  Future<List<Room>> getRoomsForLocation(String locationId) {
    _ensureReady();
    return rooms.getFor(locationId);
  }

  @override
  Future<Room?> getRoomById(String id) {
    _ensureReady();
    return rooms.getById(id);
  }

  @override
  Future<Room> addRoom(Room room) {
    _ensureReady();
    Room rm = room.withTouched();
    return rooms.upsert(rm);
  }

  @override
  Future<Room> updateRoom(Room room) {
    _ensureReady();
    Room rm = room.withTouched();
    return rooms.upsert(rm);
  }

  @override
  Future<Room> upsertRoom(Room room) {
    _ensureReady();
    Room rm = room.withTouched();
    return rooms.upsert(rm);
  }

  @override
  Future<void> deleteRoom(String id) {
    _ensureReady();
    return rooms.deleteById(id);
  }

  @override
  Future<void> clearAllData() async {
    _ensureReady();
    await db.transaction(() async {
      await db.delete(db.rooms).go();
      await db.delete(db.locations).go();
    });
  }
}
