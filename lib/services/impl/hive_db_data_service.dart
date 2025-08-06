// --- services/impl/hive_db_data_service.dart ---
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import '../../models/room_model.dart';
import '../../models/location_model.dart';
import '../data_service_interface.dart';

final Logger _logger = Logger('HiveDatabaseService');

// Hive Db data service
class HiveDbDataService implements IDataService {
  static const String _locationsBoxName = 'locationsBox';
  static const String _roomsBoxName = 'roomsBox';

  // To store references to opened boxes
  Box<Location>? _locationsBox;
  Box<Room>? _roomsBox;
  // Box<Container>? _containersBox;
  // Box<Item>? _itemsBox;

  @override
  Future<void> init() async {
    // Hive.initFlutter() should already be called in main.dart's main()
    // or in the test setup.
    _registerAdapters();
    await _openBoxes();
    _logger.info("HiveDbDataService initialized and boxes opened.");
  }

  void _registerAdapters() {
    // Register LocationAdapter if not already registered
    if (!Hive.isAdapterRegistered(LocationAdapter().typeId)) {
      Hive.registerAdapter(LocationAdapter());
      _logger.finer("LocationAdapter registered.");
    }
    // Register RoomAdapter if not already registered
    if (!Hive.isAdapterRegistered(RoomAdapter().typeId)) {
      Hive.registerAdapter(RoomAdapter());
      _logger.finer("RoomAdapter registered.");
    }
    // TODO: Register adapters for Container and Item when they are created
  }

  Future<void> _openBoxes() async {
    _locationsBox = await Hive.openBox<Location>(_locationsBoxName);
    _logger.fine(
      "Locations box '$_locationsBoxName' opened. Entries: ${_locationsBox?.length ?? 'N/A'}",
    );
    _roomsBox = await Hive.openBox<Room>(_roomsBoxName);
    _logger.fine(
      "Rooms box '$_roomsBoxName' opened. Entries: ${_roomsBox?.length ?? 'N/A'}",
    );
    // TODO: Open boxes for Container and Item when they are created
  }

  // --- Generic Box Getter ---
  Box<T> _getOpenBoxSafe<T extends HiveObject>(
    Box<T>? box,
    String boxNameForError,
  ) {
    if (box == null || !box.isOpen) {
      final errorMsg =
          '$boxNameForError box is not open. Ensure init() was called and succeeded.';
      _logger.severe(errorMsg);
      throw StateError(errorMsg);
    }
    return box;
  }

  // --- Specific Box Accessors ---
  Box<Location> get _locBoxSafe =>
      _getOpenBoxSafe<Location>(_locationsBox, 'Locations');
  Box<Room> get _roomBoxSafe => _getOpenBoxSafe<Room>(_roomsBox, 'Rooms');
  // Box<Container> get _containerBoxSafe => _getOpenBoxSafe<Container>(_containersBox, 'Containers');
  // Box<Item> get _itemBoxSafe => _getOpenBoxSafe<Item>(_itemsBox, 'Items');

  // --- Location Operations ---

  @override
  Stream<List<Location>> getLocationsStream() async* {
    _logger.fine(
      "getLocationsStream: Yielding initial values and then watching box.",
    );
    yield _locBoxSafe.values.toList(); // Initial data
    yield* _locBoxSafe.watch().map((event) {
      _logger.finer(
        'Locations box changed (key: ${event.key}, value: ${event.value}, deleted: ${event.deleted}), emitting new full list.',
      );
      return _locBoxSafe.values.toList();
    });
  }

  @override
  Future<List<Location>> getAllLocations() async {
    _logger.fine("getAllLocations called.");
    return _locBoxSafe.values.toList();
  }

  @override
  Future<Location?> getLocationById(String id) async {
    _logger.finer("getLocationById: Retrieving location with id '$id'.");
    return _locBoxSafe.get(id);
  }

  @override
  Future<Location> addLocation(Location location) async {
    await _locBoxSafe.put(location.id, location);
    _logger.info(
      'Added location: "${location.name}" (ID: ${location.id}). Timestamps: Created: ${location.createdAt}, Updated: ${location.updatedAt}.',
    );
    return location;
  }

  @override
  Future<Location> updateLocation(Location location) async {
    location.touch();

    if (_locBoxSafe.containsKey(location.id)) {
      await _locBoxSafe.put(location.id, location);
      _logger.info(
        'Updated location: "${location.name}" (ID: ${location.id}). UpdatedAt: ${location.updatedAt}.',
      );
      return location;
    } else {
      _logger.warning(
        'Attempted to update non-existent location with id: ${location.id}. Location not updated.',
      );
      throw StateError(
        'Attempted to update non-existent location with id: ${location.id}',
      );
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    final locationToDelete = _locBoxSafe.get(id);
    if (locationToDelete != null) {
      _logger.info(
        "Starting deletion process for location: '${locationToDelete.name}' (ID: $id).",
      );

      // 1. Find all rooms associated with this location
      final roomsToDelete = _roomBoxSafe.values
          .where((room) => room.locationId == id)
          .map((room) => room.id)
          .toList();

      if (roomsToDelete.isNotEmpty) {
        _logger.fine(
          "Found ${roomsToDelete.length} room(s) associated with location '${locationToDelete.name}' (ID: $id) to delete.",
        );
        for (final roomIdToDelete in roomsToDelete) {
          _logger.finer(
            "Cascading delete for room ID: $roomIdToDelete from location $id.",
          );
          await deleteRoom(roomIdToDelete);
        }
      } else {
        _logger.fine(
          "No rooms found associated with location '${locationToDelete.name}' (ID: $id) for cascading delete.",
        );
      }

      // 2. Delete the location itself
      await _locBoxSafe.delete(id);
      _logger.info(
        "Successfully deleted location '${locationToDelete.name}' (ID: $id) and its associated rooms.",
      );
    } else {
      _logger.warning('Attempted to delete non-existent location with id: $id');
    }
  }

  // --- Room Operations ---

  @override
  Stream<List<Room>> getRoomsStream(String locationId) async* {
    _logger.fine(
      "getRoomsStream for locationId '$locationId': Yielding initial values and then watching box.",
    );
    // Initial data: filter rooms by locationId
    yield _roomBoxSafe.values
        .where((room) => room.locationId == locationId)
        .toList();

    // Watch for changes in the entire rooms box
    yield* _roomBoxSafe.watch().map((event) {
      _logger.finer(
        'Rooms box changed (key: ${event.key}, value: ${event.value}, deleted: ${event.deleted}), emitting new filtered list for locationId "$locationId".',
      );
      // Re-filter by locationId on every change
      return _roomBoxSafe.values
          .where((room) => room.locationId == locationId)
          .toList();
    });
  }

  @override
  Future<List<Room>> getRoomsForLocation(String locationId) async {
    _logger.fine("getRoomsForLocation called for locationId '$locationId'.");
    return _roomBoxSafe.values
        .where((room) => room.locationId == locationId)
        .toList();
  }

  @override
  Future<Room?> getRoomById(String roomId) async {
    _logger.finer("getRoomById: Retrieving room with id '$roomId'.");
    return _roomBoxSafe.get(roomId);
  }

  @override
  Future<Room> addRoom(Room room) async {
    await _roomBoxSafe.put(room.id, room);
    _logger.info(
      'Added room: "${room.name}" (ID: ${room.id}) to location: ${room.locationId}. Timestamps: Created: ${room.createdAt}, Updated: ${room.updatedAt}.',
    );
    return room;
  }

  @override
  Future<Room> updateRoom(Room room) async {
    room.touch();

    if (_roomBoxSafe.containsKey(room.id)) {
      await _roomBoxSafe.put(room.id, room);
      _logger.info(
        'Updated room: "${room.name}" (ID: ${room.id}). UpdatedAt: ${room.updatedAt}.',
      );
      return room;
    } else {
      _logger.warning(
        'Attempted to update non-existent room with id: ${room.id}. Room not updated.',
      );
      throw StateError(
        'Attempted to update non-existent room with id: ${room.id}',
      );
    }
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    final roomToDelete = _roomBoxSafe.get(roomId);
    if (roomToDelete != null) {
      // TODO: Implement cascading delete for Containers and Items within this room if needed in the future.
      _logger.info(
        "Deleting room '${roomToDelete.name}' (ID: $roomId). (Associated containers/items NOT YET handled).",
      );
      await _roomBoxSafe.delete(roomId);
      _logger.info(
        'Successfully deleted room: "${roomToDelete.name}" (ID: $roomId)',
      );
    } else {
      _logger.warning('Attempted to delete non-existent room with id: $roomId');
    }
  }

  // --- General Data Operations & Cleanup ---

  @override
  Future<void> clearAllData() async {
    _logger.info("Clearing all data from Hive boxes...");
    int locClearedCount = 0;
    int roomClearedCount = 0;

    if (_locationsBox?.isOpen ?? false) {
      locClearedCount = await _locBoxSafe.clear();
      _logger.info("Locations box cleared. $locClearedCount entries removed.");
    } else {
      _logger.warning("Locations box was not open or available to clear.");
    }

    if (_roomsBox?.isOpen ?? false) {
      roomClearedCount = await _roomBoxSafe.clear();
      _logger.info("Rooms box cleared. $roomClearedCount entries removed.");
    } else {
      _logger.warning("Rooms box was not open or available to clear.");
    }
    // TODO: Clear Container and Item boxes when they are added

    _logger.info(
      "All relevant Hive data cleared. Total locations cleared: $locClearedCount, Total rooms cleared: $roomClearedCount.",
    );
  }

  @override
  Future<void> dispose() async {
    _logger.info("Closing Hive boxes...");
    await _locationsBox?.close();
    _logger.fine("Locations box closed if it was open.");
    await _roomsBox?.close();
    _logger.fine("Rooms box closed if it was open.");
    // TODO: Close Container and Item boxes when they are added
    _logger.info("All relevant Hive boxes in this service are now closed.");
  }
}
