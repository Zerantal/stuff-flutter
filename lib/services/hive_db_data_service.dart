// --- services/hive_database_service.dart ---
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';

import 'data_service_interface.dart';
import '../models/location_model.dart';

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
      _logger.severe(
        'Locations box is not open. Ensure init() was called and succeeded.',
      );
      throw StateError('Locations Box is not initialized or open.');
    }
    return _locationsBox!;
  }

  // --- Location Operations ---
  @override
  Future<List<Location>> getAllLocations() async {
    return _locBox.values.toList();
  }

  @override
  Future<Location?> getLocationById(String id) async {
    // Hive boxes store key-value pairs. If 'id' is your Hive key, it's direct.
    // If 'id' is a field within your Location object, you need to iterate or use a secondary index.
    // Assuming 'id' is a field in the Location object and not the Hive key:
    return _locBox.values.firstWhereOrNull((location) => location.id == id);
    // If Location.id IS the Hive key (and you used box.put(location.id, location)):
    // return _locBox.get(id);
  }

  @override
  Future<void> addLocation(Location location) async {
    // If Location.id should be the Hive key:
    await _locBox.put(location.id, location);
    // If you want Hive to auto-generate keys (integers):
    // await _locBox.add(location);
    _logger.fine('Added location: ${location.name}');
  }

  @override
  Future<void> updateLocation(Location location) async {
    // For update to work with put, the key must exist.
    // Assuming location.id is the key used when adding.
    if (_locBox.containsKey(location.id)) {
      await _locBox.put(location.id, location);
      _logger.fine('Updated location: ${location.name}');
    } else {
      _logger.warning(
        'Attempted to update non-existent location with id: ${location.id}',
      );
      // Optionally throw an error or handle as a new add
    }
  }

  @override
  Future<void> deleteLocation(String id) async {
    // Assuming location.id is the Hive key.
    await _locBox.delete(id);
    _logger.fine('Deleted location with id: $id');
  }

  @override
  Stream<List<Location>> watchAllLocations() async* {
    yield _locBox.values.toList();

    yield* _locBox.watch().map((event) {
      _logger.finer(
        'Locations box changed, emitting new list. Key: ${event.key}, Deleted: ${event.deleted}',
      );
      return _locBox.values.toList();
    });
  }

  // --- Development & Debugging ---
  @override
  Future<void> populateSampleData() async {
    _logger.info("Populating all sample data into Hive...");
    await clearAllData(); // Clear everything before populating

    await _populateSampleLocations();

    _logger.info("Sample data population complete for Hive.");
  }

  @override
  Future<void> clearAllData() async {
    _logger.info("Clearing all data from Hive boxes...");
    await _locBox.clear();
    _logger.info("All Hive data cleared.");
  }

  Future<void> _populateSampleLocations() async {
    // Using location.id as the Hive key
    await addLocation(
      Location(
        id: 'loc1',
        name: 'Home',
        imagePaths: ['assets/images/home.png'],
      ),
    );
    await addLocation(
      Location(id: 'loc2', name: 'Investment Property', imagePaths: []),
    );
    await addLocation(
      Location(
        id: 'loc3',
        name: 'Office',
        imagePaths: ['assets/images/office.png'],
      ),
    );
    _logger.info("${_locBox.length} sample locations added to Hive.");
  }

  // --- Cleanup ---
  @override
  Future<void> dispose() async {
    _logger.info("Closing Hive boxes...");
    await _locationsBox?.close();

    _logger.info("Hive boxes closed.");
  }
}
