// lib/services/contracts/data_service_interface.dart
import 'container_store.dart';
import 'item_store.dart';
import 'location_store.dart';
import 'room_store.dart';

abstract class IDataService implements ILocationStore, IRoomStore, IContainerStore, IItemStore {
  // --- Initialization & Setup ---
  /// Initializes the database service.
  /// This might involve setting up connections, registering adapters (for local DBs), etc.
  /// Should be called once when the app starts.
  Future<void> init();

  /// Clears all data from all relevant stores.
  Future<void> clearAllData();

  /// Closes any open connections or resources.
  /// Important for some database implementations.
  Future<void> dispose();
}
