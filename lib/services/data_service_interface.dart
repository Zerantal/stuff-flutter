// --- services/data_service_interface.dart ---
import '../models/location_model.dart';

abstract class IDataService {
  // --- Initialization & Setup ---
  /// Initializes the database service.
  /// This might involve setting up connections, registering adapters (for local DBs), etc.
  /// Should be called once when the app starts.
  Future<void> init();

  // --- Location Operations ---
  Future<List<Location>> getAllLocations();
  Future<Location?> getLocationById(String id);
  Future<void> addLocation(Location location);
  Future<void> updateLocation(Location location);
  Future<void> deleteLocation(String id);
  Stream<List<Location>> watchAllLocations();

  // --- Development & Debugging ---
  /// Populates the database with a predefined set of sample data.
  /// Should typically clear existing data first.
  Future<void> populateSampleData();

  /// Clears all data from all relevant stores.
  Future<void> clearAllData();

  // --- Cleanup ---
  /// Closes any open connections or resources.
  /// Important for some database implementations.
  Future<void> dispose();
}
