// lib/services/impl/drift_data_service.dart

import 'package:clock/clock.dart';

import '../../domain/models/location_model.dart';
import '../../domain/models/room_model.dart';
import '../../domain/models/container_model.dart';
import '../../domain/models/item_model.dart';
import '../../data/drift/database.dart';
import '../contracts/data_service_interface.dart';

class DriftDataService implements IDataService {
  DriftDataService(this.db)
    : locations = LocationDao(db),
      rooms = RoomDao(db),
      containers = ContainerDao(db),
      items = ItemDao(db);

  final AppDatabase db;
  final LocationDao locations;
  final RoomDao rooms;
  final ContainerDao containers;
  final ItemDao items;

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
  Stream<List<Location>> watchLocations() {
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
  Stream<List<Room>> watchRooms(String locationId) {
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

  // --------------------- Containers ---------------------

  @override
  Stream<List<Container>> watchRoomContainers(String roomId) {
    _ensureReady();
    return containers.watchTopLevelByRoom(roomId);
  }

  @override
  Stream<List<Container>> watchChildContainers(String parentContainerId) {
    _ensureReady();
    return containers.watchChildren(parentContainerId);
  }

  @override
  Stream<List<Container>> watchLocationContainers(String locationId) {
    _ensureReady();
    return containers.watchTopLevelByLocation(locationId);
  }

  @override
  Stream<List<Container>> watchAllContainers() {
    _ensureReady();
    return watchAllContainers();
  }

  @override
  Future<List<Container>> getRoomContainers(String roomId) {
    _ensureReady();
    return watchRoomContainers(roomId).first;
  }

  @override
  Future<List<Container>> getChildContainers(String parentContainerId) {
    _ensureReady();
    return watchChildContainers(parentContainerId).first;
  }

  @override
  Future<List<Container>> getLocationContainers(String locationId) {
    _ensureReady();
    return watchLocationContainers(locationId).first;
  }

  @override
  Future<List<Container>> getAllContainers() {
    _ensureReady();
    return watchAllContainers().first;
  }

  @override
  Future<Container?> getContainerById(String id) {
    _ensureReady();
    return containers.getById(id);
  }

  @override
  Future<Container> addContainer(Container container) {
    _ensureReady();
    final touched = container.withTouched();
    return containers.upsert(touched);
  }

  @override
  Future<Container> updateContainer(Container container) {
    _ensureReady();
    final touched = container.withTouched();
    return containers.upsert(touched);
  }

  @override
  Future<Container> upsertContainer(Container container) {
    _ensureReady();
    final touched = container.withTouched();
    return containers.upsert(touched);
  }

  @override
  Future<void> deleteContainer(String id) {
    _ensureReady();
    return containers.deleteById(id);
  }

  // ----------------------- Items -----------------------

  @override
  Stream<List<Item>> watchRoomItems(String roomId) {
    _ensureReady();
    return items.watchInRoom(roomId);
  }

  @override
  Stream<List<Item>> watchContainerItems(String containerId) {
    _ensureReady();
    return items.watchInContainer(containerId);
  }

  // Items in location (room-level only)
  @override
  Stream<List<Item>> watchLocationItems(String locationId) {
    _ensureReady();
    return items.watchInLocation(locationId);
  }

  @override
  Stream<List<Item>> watchAllItems() {
    _ensureReady();
    return watchAllItems();
  }

  @override
  Future<List<Item>> getItemsInRoom(String roomId) {
    _ensureReady();
    return watchRoomItems(roomId).first;
  }

  @override
  Future<List<Item>> getItemsInContainer(String containerId) {
    _ensureReady();
    return watchContainerItems(containerId).first;
  }

  @override
  Future<Item?> getItemById(String id) {
    _ensureReady();
    return items.getById(id);
  }

  @override
  Future<Item> addItem(Item item) {
    _ensureReady();
    final touched = item.withTouched();
    return items.upsert(touched);
  }

  @override
  Future<Item> updateItem(Item item) {
    _ensureReady();
    final touched = item.withTouched();
    return items.upsert(touched);
  }

  @override
  Future<Item> upsertItem(Item item) {
    _ensureReady();
    final touched = item.withTouched();
    return items.upsert(touched);
  }

  @override
  Future<void> deleteItem(String id) {
    _ensureReady();
    return items.deleteById(id);
  }

  @override
  Future<void> setItemArchived(String id, bool archived) async {
    _ensureReady();
    await items.setArchived(id, archived, updatedAt: clock.now());
  }
}
