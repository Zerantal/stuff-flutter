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
      await dataService.runInTransaction(() async {
        final loc = await dataService.getLocationById(locationId);
        if (loc == null) return;

        final imagesToBeDeleted = <String>{}..addAll(loc.imageGuids);

        final rooms = await dataService.getRoomsForLocation(locationId);
        for (final room in rooms) {
          imagesToBeDeleted.addAll(room.imageGuids);

          final containers = await dataService.getRoomContainers(room.id);
          for (final c in containers) {
            imagesToBeDeleted.addAll(c.imageGuids); // caller handles top-level container
            await _collectContainerCascade(c.id, imagesToBeDeleted);
          }

          final items = await dataService.getItemsInRoom(room.id);
          imagesToBeDeleted.addAll(items.expand((i) => i.imageGuids));
        }

        await dataService.deleteLocation(locationId);

        await imageService.deleteImages(imagesToBeDeleted);
      });
    } catch (e, s) {
      _log.severe("Failed to delete location $locationId", e, s);
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await dataService.runInTransaction(() async {
        final room = await dataService.getRoomById(roomId);
        await dataService.deleteRoom(roomId);

        if (room == null) return;

        final imagesToBeDeleted = <String>{}..addAll(room.imageGuids);

        final containers = await dataService.getRoomContainers(room.id);
        for (final c in containers) {
          imagesToBeDeleted.addAll(c.imageGuids);
          await _collectContainerCascade(c.id, imagesToBeDeleted);
        }

        final items = await dataService.getItemsInRoom(room.id);
        imagesToBeDeleted.addAll(items.expand((i) => i.imageGuids));

        await imageService.deleteImages(imagesToBeDeleted);
      });
    } catch (e, s) {
      _log.severe("Failed to delete room $roomId", e, s);
      rethrow;
    }
  }

  Future<void> deleteContainer(String containerId) async {
    try {
      await dataService.runInTransaction(() async {
        final c = await dataService.getContainerById(containerId);
        if (c == null) return;

        await dataService.deleteContainer(containerId);

        final imagesToBeDeleted = <String>{}..addAll(c.imageGuids);

        await _collectContainerCascade(c.id, imagesToBeDeleted);
        await dataService.deleteContainer(c.id);

        await imageService.deleteImages(imagesToBeDeleted);
      });
    } catch (e, s) {
      _log.severe("Failed to delete container $containerId", e, s);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _collectContainerCascade(String parentId, Set<String> imagesToBeDeleted) async {
    // children
    final children = await dataService.getChildContainers(parentId);
    for (final child in children) {
      imagesToBeDeleted.addAll(child.imageGuids);
      await _collectContainerCascade(child.id, imagesToBeDeleted);
    }

    // items
    final items = await dataService.getItemsInContainer(parentId);
    imagesToBeDeleted.addAll(items.expand((i) => i.imageGuids));
  }
}
