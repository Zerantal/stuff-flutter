// --- services/data_service_interface.dart ---
import '../models/location_model.dart';
import '../models/room_model.dart';

abstract class IDataService {
  // --- Initialization & Setup ---
  /// Initializes the database service.
  /// This might involve setting up connections, registering adapters (for local DBs), etc.
  /// Should be called once when the app starts.
  Future<void> init();

  // --- Location Operations ---
  Future<List<Location>> getAllLocations();
  Stream<List<Location>> getLocationsStream();
  Future<Location?> getLocationById(String id);
  Future<void> addLocation(Location location);
  Future<void> updateLocation(Location location);
  Future<void> deleteLocation(String id);

  // --- Room Operations ---
  Stream<List<Room>> getRoomsStream(String locationId);
  Future<List<Room>> getRoomsForLocation(String locationId);
  Future<Room?> getRoomById(String roomId);
  Future<void> addRoom(Room room);
  Future<void> updateRoom(Room room);
  Future<void> deleteRoom(String roomId);

  /// Clears all data from all relevant stores.
  Future<void> clearAllData();

  // --- Cleanup ---
  /// Closes any open connections or resources.
  /// Important for some database implementations.
  Future<void> dispose();
}
