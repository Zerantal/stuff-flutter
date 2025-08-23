// lib/services/ops/db_ops.dart

import 'package:logging/logging.dart';

import '../contracts/data_service_interface.dart';
import '../contracts/image_data_service_interface.dart';
import '../utils/image_data_service_extensions.dart';

final _log = Logger('DbOps');

class DbOps {
  final IDataService dataService;
  final IImageDataService imageService;

  const DbOps(this.dataService, this.imageService);

  Future<void> deleteLocation(String locationId) async {
    try {
      // Need to get all photos associated with location first
      final loc = await dataService.getLocationById(locationId);
      if (loc == null) return;

      final imagesToBeDeleted = List<String>.from(loc.imageGuids);

      final rooms = await dataService.getRoomsForLocation(locationId);
      imagesToBeDeleted.addAll(rooms.expand((room) => room.imageGuids));

      await dataService.deleteLocation(locationId);

      imageService.deleteImages(imagesToBeDeleted);
    } catch (e, s) {
      _log.severe("Failed to delete location $locationId", e, s);
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final r = await dataService.getRoomById(roomId);
      await dataService.deleteRoom(roomId);
      if (r != null && r.imageGuids.isNotEmpty) {
        imageService.deleteImages(List<String>.from(r.imageGuids));
      }
    } catch (e, s) {
      _log.severe("Failed to delete room $roomId", e, s);
      rethrow;
    }
  }
}
