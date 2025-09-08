// lib/features/location/viewmodels/locations_view_model.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../services/ops/db_ops.dart';
import '../../../shared/image/image_ref.dart';
import '../../../domain/models/location_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';

final Logger _log = Logger('LocationsViewModel');

/// Simple DTO the UI can render directly.
class LocationListItem {
  final Location location;
  final List<ImageRef> images; // empty => placeholder in the view
  const LocationListItem({required this.location, required this.images});
}

class LocationsViewModel {
  LocationsViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
  }) : _data = dataService,
       _imageDataService = imageDataService,
       _dbOps = DbOps(dataService, imageDataService) {
    // Map the domain stream to UI-ready items without doing any I/O verification.
    locations = _data
        .watchLocations()
        .map((list) => list.map(_toListItem).toList(growable: false))
        .handleError((e, s) {
          _log.severe('locations stream error', e, s);
        });

    _log.fine('Subscribed to locations stream');
  }

  static LocationsViewModel create(BuildContext ctx) {
    {
      return LocationsViewModel(
        dataService: ctx.read<IDataService>(),
        imageDataService: ctx.read<IImageDataService>(),
      );
    }
  }

  final IDataService _data;
  final IImageDataService _imageDataService;
  final DbOps _dbOps;

  late final Stream<List<LocationListItem>> locations;

  Future<void> deleteLocationById(String locationId) => _dbOps.deleteLocation(locationId);

  // ---- internals -----------------------------------------------------------

  // Build list item with zero-I/O image refs for smooth scrolling.
  LocationListItem _toListItem(Location loc) {
    final guids = loc.imageGuids;
    final refs = _imageDataService.refsForGuids(guids);
    return LocationListItem(location: loc, images: refs);
  }
}
