// services/sample_data_populator.dart
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/location_model.dart';
import '../data_service_interface.dart';
import '../image_data_service_interface.dart';

final Logger _logger = Logger('SampleDataPopulator');
const Uuid _uuid = Uuid(); // For generating unique IDs for temp files if needed

class SampleDataPopulator {
  final IDataService dataService;
  final IImageDataService?
  imageDataService; // Nullable if image saving is optional

  SampleDataPopulator({
    required this.dataService,
    this.imageDataService, // optional
  });

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

    // Prepare sample locations
    List<String> homeImageGuids = [];
    List<String> officeImageGuids = [];

    if (imageDataService != null) {
      // Check service once before calling helper multiple times
      homeImageGuids = await _processAndSaveSampleImage(
        'assets/images/home.png',
        'home.png',
      );
      officeImageGuids = await _processAndSaveSampleImage(
        'assets/images/office.png',
        'office.png',
      );
    } else {
      _logger.info(
        "IImageDataService is null. Skipping all sample image processing.",
      );
    }

    final locationsToCreate = [
      Location(
        id: 'loc_sample_1',
        name: 'Cozy Home',
        description: 'Primary residence with a small garden.',
        address: '123 Sample St, Testville',
        imageGuids: homeImageGuids,
      ),
      Location(
        id: 'loc_sample_2',
        name: 'Downtown Office',
        description: 'Vacuum cleaner business.',
        address: '456 Dev Ave, Coder City',
        imageGuids: officeImageGuids,
      ),
      Location(
        id: 'loc_sample_3',
        name: 'Lakehouse Retreat',
        description: 'Vacation property by the lake.',
        address: '789 Shore Ln, Mockington',
        imageGuids: [], // No specific image for this sample
      ),
    ];

    // 3. Add locations using IDataService
    for (final location in locationsToCreate) {
      try {
        await dataService.addLocation(location);
        _logger.finer("Added sample location: ${location.name}");
      } catch (e) {
        _logger.warning("Failed to add sample location '${location.name}': $e");
      }
    }

    _logger.info(
      "Sample data population process complete. ${locationsToCreate.length} locations attempted.",
    );
  }
}
