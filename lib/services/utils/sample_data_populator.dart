// services/sample_data_populator.dart
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/location_model.dart';
import '../../models/room_model.dart';
import '../data_service_interface.dart';
import '../image_data_service_interface.dart';

final Logger _logger = Logger('SampleDataPopulator');
const Uuid _uuid = Uuid(); // For generating unique IDs for temp files if needed

class SampleDataPopulator {
  final IDataService dataService;
  final IImageDataService? imageDataService;

  SampleDataPopulator({required this.dataService, this.imageDataService});

  Future<File?> _assetToTempFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFileName = '${_uuid.v4()}-${assetPath.split('/').last}';
      final file = File('${tempDir.path}/$tempFileName');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      _logger.finer('Asset $assetPath copied to temporary file ${file.path}');
      return file;
    } catch (e) {
      _logger.warning(
        'Failed to convert asset $assetPath to temporary file: $e',
      );
      return null;
    }
  }

  Future<List<String>> _processAndSaveSampleImage(
    String assetPath,
    String imageFriendlyName,
  ) async {
    List<String> imageGuids = [];
    if (imageDataService == null) {
      _logger.info(
        "IImageDataService is null, skipping image processing for $imageFriendlyName.",
      );
      return imageGuids; // Return empty list if no service
    }

    File? tempImageFile = await _assetToTempFile(assetPath);
    if (tempImageFile != null) {
      try {
        final guid = await imageDataService!.saveUserImage(tempImageFile);
        imageGuids.add(guid);
        _logger.info(
          "Sample '$imageFriendlyName' ($assetPath) saved with GUID: $guid",
        );
      } catch (e) {
        _logger.warning(
          "Failed to save sample asset '$assetPath' via IImageDataService: $e",
        );
      } finally {
        try {
          if (await tempImageFile.exists()) {
            await tempImageFile.delete();
            _logger.finer(
              'Successfully deleted temp file ${tempImageFile.path} for $imageFriendlyName',
            );
          }
        } catch (deleteError) {
          _logger.warning(
            "Failed to delete temp file ${tempImageFile.path} for $imageFriendlyName: $deleteError",
          );
        }
      }
    } else {
      _logger.warning(
        "Could not create temporary file for asset $assetPath ($imageFriendlyName).",
      );
    }
    return imageGuids;
  }

  Future<void> populate() async {
    _logger.info("Starting sample data population...");

    await dataService.clearAllData();
    _logger.info("Existing data cleared via IDataService.");

    // Clear existing user images IF the service is available
    if (imageDataService != null) {
      try {
        _logger.info(
          "Attempting to clear all user images via IImageDataService...",
        );
        await imageDataService!.clearAllUserImages();
        _logger.info("Successfully cleared all user images.");
      } catch (e, s) {
        _logger.severe(
          "Error clearing user images during population: $e",
          e,
          s,
        );
      }
    } else {
      _logger.info(
        "IImageDataService is null. Skipping clearing of user images.",
      );
    }

    // --- 1. Prepare Sample Image GUIDs (Locations & Rooms) ---
    List<String> homeImageGuids = [];
    List<String> officeImageGuids = [];
    List<String> kitchenImageGuids = [];
    List<String> livingRoomImageGuids = [];
    List<String> officeRoomImageGuids = [];
    List<String> serverRoomImageGuids = [];

    if (imageDataService != null) {
      _logger.info(
        "Processing sample images as IImageDataService is available...",
      );
      // Location Images
      homeImageGuids = await _processAndSaveSampleImage(
        'assets/images/sample/locations/home.jpg', // Assuming a subfolder for clarity
        'location_home.jpg',
      );
      officeImageGuids = await _processAndSaveSampleImage(
        'assets/images/sample/locations/office.jpg',
        'location_office.jpg',
      );
      // Room Images
      kitchenImageGuids = await _processAndSaveSampleImage(
        'assets/images/sample/rooms/kitchen.jpg', // Assuming a subfolder
        'room_kitchen.jpg',
      );
      livingRoomImageGuids = await _processAndSaveSampleImage(
        'assets/images/sample/rooms/living_room.jpg',
        'room_living_room.jpg',
      );
      officeRoomImageGuids = await _processAndSaveSampleImage(
        'assets/images/sample/rooms/office_room.jpg',
        'room_office_room.jpg',
      );
      serverRoomImageGuids = await _processAndSaveSampleImage(
        'assets/images/sample/rooms/server_room.jpg',
        'room_server_room.jpg',
      );
      _logger.info("Sample image processing complete.");
    } else {
      _logger.info(
        "IImageDataService is null. Skipping all sample image processing.",
      );
    }

    // --- 2. Create Sample Locations ---
    final homeLocationId = 'loc_sample_home';
    final officeLocationId = 'loc_sample_office';
    final lakehouseLocationId = 'loc_sample_lakehouse';

    final locationsToCreate = [
      Location(
        id: homeLocationId,
        name: 'Cozy Home',
        description: 'Primary residence with a small garden.',
        address: '123 Sample St, Testville',
        imageGuids: homeImageGuids,
      ),
      Location(
        id: officeLocationId,
        name: 'Downtown Office',
        description: 'Vacuum cleaner business.',
        address: '456 Dev Ave, Coder City',
        imageGuids: officeImageGuids,
      ),
      Location(
        id: lakehouseLocationId,
        name: 'Lakehouse Retreat',
        description: 'Vacation property by the lake.',
        address: '789 Shore Ln, Mockington',
        imageGuids: [], // No specific image for this sample
      ),
    ];

    for (final location in locationsToCreate) {
      try {
        await dataService.addLocation(location);
        _logger.finer("Added sample location: ${location.name}");
      } catch (e) {
        _logger.warning("Failed to add sample location '${location.name}': $e");
      }
    }

    // --- 3. Create Sample Rooms and Associate with Locations ---
    final roomsToCreate = [
      // Rooms for 'Cozy Home'
      Room(
        name: 'Kitchen',
        description: 'Where delicious meals are made. Recently renovated.',
        locationId: homeLocationId, // Link to Cozy Home
        imageGuids: kitchenImageGuids,
      ),
      Room(
        name: 'Living Room',
        description: 'Comfortable seating, TV, and a fireplace.',
        locationId: homeLocationId, // Link to Cozy Home
        imageGuids: livingRoomImageGuids,
      ),
      Room(
        name: 'Master Bedroom',
        description: 'Main bedroom with an en-suite.',
        locationId: homeLocationId, // Link to Cozy Home
        imageGuids: [], // No specific image for this sample room
      ),

      // Rooms for 'Downtown Office'
      Room(
        name: 'Main Office Area',
        description: 'Open plan office with several desks.',
        locationId: officeLocationId, // Link to Downtown Office
        imageGuids: officeRoomImageGuids,
      ),
      Room(
        name: 'Server Room',
        description:
            'Houses network equipment and servers. Needs better cooling.',
        locationId: officeLocationId, // Link to Downtown Office
        imageGuids: serverRoomImageGuids,
      ),
      Room(
        name: 'Meeting Room Alpha',
        description: 'Primary meeting room with video conferencing.',
        locationId: officeLocationId, // Link to Downtown Office
        imageGuids: [], // No specific image
      ),
    ];

    for (final room in roomsToCreate) {
      try {
        await dataService.addRoom(room);
        _logger.finer(
          "Added sample room: ${room.name} to location ID ${room.locationId} (Room ID: ${room.id})",
        );
      } catch (e) {
        _logger.warning("Failed to add sample room '${room.name}': $e");
      }
    }
    _logger.info("${roomsToCreate.length} sample rooms processed.");

    _logger.info(
      "Sample data population process complete. ${locationsToCreate.length} locations attempted.",
    );
  }
}
