import '../../domain/models/location_model.dart';

abstract class ILocationStore {
  // Streams
  Stream<List<Location>> getLocationsStream();

  // Queries / commands
  Future<List<Location>> getAllLocations();
  Future<Location?> getLocationById(String id);
  Future<Location> addLocation(Location location);
  Future<Location> updateLocation(Location location);
  Future<Location> upsertLocation(Location location);
  Future<void> deleteLocation(String id);
}
