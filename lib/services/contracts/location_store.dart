import '../../domain/models/location_model.dart';

abstract class ILocationStore {
  // Streams
  Stream<List<Location>> watchLocations();

  // One shot queries
  Future<List<Location>> getAllLocations();
  Future<Location?> getLocationById(String id);

  // Commands
  Future<Location> addLocation(Location location);
  Future<Location> updateLocation(Location location);
  Future<Location> upsertLocation(Location location);
  Future<void> deleteLocation(String id);
}
