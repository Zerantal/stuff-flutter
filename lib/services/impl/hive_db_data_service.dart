// --- services/hive_database_service.dart ---
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';

import '../data_service_interface.dart';
import '../../models/location_model.dart';

final Logger _logger = Logger('HiveDatabaseService');

// Hive Db data service
class HiveDbDataService implements IDataService {
  static const String _locationsBoxName = 'locationsBox';
  // static const String _roomsBoxName = 'roomsBox';

  // To store references to opened boxes
  Box<Location>? _locationsBox;
  // Box<Room>? _roomsBox;

  @override
  Future<void> init() async {
    // Hive.initFlutter() should already be called in main.dart's main()
    // or in the test setup.
    _registerAdapters();
    await _openBoxes();
    _logger.info("HiveDbDataService initialized and boxes opened.");
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(LocationAdapter().typeId)) {
      Hive.registerAdapter(LocationAdapter());
    }
  }

  Future<void> _openBoxes() async {
    _locationsBox = await Hive.openBox<Location>(_locationsBoxName);
  }

  // Helper to ensure a box is open before use
  Box<Location> get _locBox {
    if (_locationsBox == null || !_locationsBox!.isOpen) {
      final errorMsg =
          'Locations box is not open. Ensure init() was called and succeeded.';
      _logger.severe(errorMsg);
      throw StateError(errorMsg);
    }
    return _locationsBox!;
  }

  // --- Location Operations ---

  @override
  Stream<List<Location>> getLocationsStream() async* {
    _logger.fine(
      "getLocationsStream: Yielding initial values and then watching box.",
    );
    yield _locBox.values.toList();
    yield* _locBox.watch().map((event) {
      _logger.finer(
        'Locations box changed (event: ${event.key}, deleted: ${event.deleted}), emitting new full list.',
      );
      return _locBox.values.toList();
    });
  }

  @override
  Future<List<Location>> getAllLocations() async {
    _logger.fine("getAllLocations called.");
    return _locBox.values.toList();
  }

  @override
  Future<Location?> getLocationById(String id) async {
    return _locBox.values.firstWhereOrNull((location) => location.id == id);
  }

  @override
  Future<void> addLocation(Location location) async {
    await _locBox.put(location.id, location);
    _logger.fine('Added location: ${location.name}.');
  }

  @override
  Future<void> updateLocation(Location location) async {
    if (_locBox.containsKey(location.id)) {
      await _locBox.put(location.id, location);
      _logger.fine('Updated location: ${location.name}.');
    } else {
      _logger.warning(
        'Attempted to update non-existent location with id: ${location.id}',
      );
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    await _locBox.delete(id);
    _logger.fine('Deleted location with id: $id');
  }

  @override
  Future<void> clearAllData() async {
    _logger.info("Clearing all data from Hive boxes...");
    await _locBox.clear();
    _logger.info("All Hive data cleared.");
  }

  // --- Cleanup ---
  @override
  Future<void> dispose() async {
    _logger.info("Closing Hive boxes...");
    await _locationsBox?.close();

    _logger.info("Hive boxes closed.");
  }
}
