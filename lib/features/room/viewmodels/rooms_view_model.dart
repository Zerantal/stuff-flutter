// lib/features/room/viewmodels/rooms_view_model.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/room_model.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../services/ops/db_ops.dart';
import '../../../shared/image/image_ref.dart';

final Logger _log = Logger('RoomsViewModel');

/// Simple DTO the UI can render directly.
class RoomListItem {
  final Room room;
  final List<ImageRef> images; // empty => placeholder in the view
  const RoomListItem({required this.room, required this.images});
}

class RoomsViewModel {
  final IDataService _dataService;
  final IImageDataService _imageService;
  final String locationId;
  final DbOps _dbOps;

  late final Stream<List<RoomListItem>> rooms;

  RoomsViewModel({
    required IDataService data,
    required IImageDataService images,
    required this.locationId,
  }) : _dataService = data,
       _imageService = images,
       _dbOps = DbOps(data, images) {
    rooms = _dataService
        .getRoomsStream(locationId)
        .map(
          (list) => list
              .map((r) => RoomListItem(room: r, images: _imageService.refsForGuids(r.imageGuids)))
              .toList(growable: false),
        )
        .handleError((e, s) => _log.severe('rooms stream error', e, s));

    _log.fine('Subscribed to rooms stream');
  }

  String? get locationName => null; // TODO: implement this?

  static RoomsViewModel forLocation(BuildContext ctx, String locationId) {
    return RoomsViewModel(
      data: ctx.read<IDataService>(),
      images: ctx.read<IImageDataService>(),
      locationId: locationId,
    );
  }

  Future<void> deleteRoom(String roomId) => _dbOps.deleteRoom(roomId);
}
