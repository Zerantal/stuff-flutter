import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import '../models/location_model.dart';
// Import other models as you create them (Room, Container, Item)

final Logger _logger = Logger('DatabaseService');

class DatabaseService {
  // Box names
  static const String locationsBoxName = 'locationsBox';

  // Add other box names here:
  // static const String roomsBoxName = 'roomsBox';
  // static const String containersBoxName = 'containersBox';
  // static const String itemsBoxName = 'itemsBox';

  // --- Initialization ---
  static Future<void> init() async {
    // Hive.initFlutter() should already be called in main.dart
    Hive.registerAdapter(LocationAdapter());
    // Register other adapters here:
    // Hive.registerAdapter(RoomAdapter());
    // Hive.registerAdapter(ContainerAdapter());
    // Hive.registerAdapter(ItemAdapter());

    await Hive.openBox<Location>(locationsBoxName);
    // Open other boxes here:
    // await Hive.openBox<Room>(roomsBoxName);
    // await Hive.openBox<Container>(containersBoxName);
    // await Hive.openBox<Item>(itemsBoxName);
  }

  // --- Getters for Boxes (Convenience) ---
  static Box<Location> get locationsBox => Hive.box<Location>(locationsBoxName);

  // static Box<Room> get roomsBox => Hive.box<Room>(roomsBoxName);
  // static Box<Container> get containersBox => Hive.box<Container>(containersBoxName);
  // static Box<Item> get itemsBox => Hive.box<Item>(itemsBoxName);

  // --- Sample Data Population ---
  static Future<void> populateSampleData() async {
    _logger.info("Populating all sample data...");
    await _clearAllData(); // Clear everything before populating

    // Populate Locations
    await _populateSampleLocations();
    // Populate Rooms (you'll create this method)
    // await _populateSampleRooms();
    // Populate Containers (you'll create this method)
    // await _populateSampleContainers();
    // Populate Items (you'll create this method)
    // await _populateSampleItems();

    _logger.info("Sample data population complete.");
  }

  static Future<void> _clearAllData() async {
    _logger.info("Clearing all data from Hive boxes...");
    await locationsBox.clear();
    // await roomsBox.clear();
    // await containersBox.clear();
    // await itemsBox.clear();
    _logger.info("All data cleared.");
  }

  static Future<void> _populateSampleLocations() async {
    await locationsBox.add(
      Location(
        id: 'loc1',
        name: 'Home',
        imagePaths: ['assets/images/home.png'],
      ),
    );
    await locationsBox.add(
      Location(id: 'loc2', name: 'Investment Property', imagePaths: []),
    );
    await locationsBox.add(
      Location(
        id: 'loc3',
        name: 'Office',
        imagePaths: ['assets/images/office.png'],
      ),
    );
    _logger.info("${locationsBox.length} sample locations added.");
  }

  // --- Example: Placeholder for populating sample rooms ---
  // static Future<void> _populateSampleRooms() async {
  //   // Example: Assuming Room model exists and is registered
  //   // This would depend on your Room model having a locationId
  //   await roomsBox.add(Room(id: 'room1', locationId: 'loc1', name: 'Main Desk Area'));
  //   await roomsBox.add(Room(id: 'room2', locationId: 'loc1', name: 'Bookshelf Corner'));
  //   await roomsBox.add(Room(id: 'room3', locationId: 'loc2', name: 'Tool Wall'));
  //   print("${roomsBox.length} sample rooms added.");
  // }

  // Add more methods for CRUD operations on locations, rooms, etc. as needed
  // e.g., Future<void> addLocation(Location location) async { ... }
  // e.g., Future<List<Location>> getAllLocations() async { ... }
}
