// lib/features/location/viewmodels/locations_view_model.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../shared/image/image_ref.dart';
import '../../../domain/models/location_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../services/utils/sample_data_populator.dart';

final Logger _log = Logger('LocationsViewModel');

/// Simple DTO the UI can render directly.
class LocationListItem {
  final Location location;
  final List<ImageRef> images; // empty => placeholder in the view
  const LocationListItem({required this.location, required this.images});
}

class LocationsViewModel with ChangeNotifier {
  LocationsViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
  }) : _data = dataService,
       _imageDataService = imageDataService {
    // Map the domain stream to UI-ready items without doing any I/O verification.

    locations = _data
        .getLocationsStream()
        .map((list) => list.map(_toListItem).toList(growable: false))
        .handleError((e, s) {
          _log.severe('locations stream error', e, s);
        });

    _log.fine('Subscribed to locations stream');
  }

  final IDataService _data;
  final IImageDataService _imageDataService;

  late final Stream<List<LocationListItem>> locations;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  Future<void> refresh() async {
    _log.fine('Refresh requested');
    await _data.getAllLocations();
  }

  Future<void> resetWithSampleData() async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      final populator = SampleDataPopulator(
        dataService: _data,
        imageDataService: _imageDataService,
      );
      await populator.populate();
      _log.info('Sample data populated');
      await _data.getAllLocations();
    } catch (e, s) {
      _log.severe('Failed to populate sample data', e, s);
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteLocationById(String id) async {
    try {
      // Need to get all photos associated with location first
      final loc = await _data.getLocationById(id);
      if (loc == null) return;

      final imagesToBeDeleted = List<String>.from(loc.imageGuids);

      final rooms = await _data.getRoomsForLocation(id);
      imagesToBeDeleted.addAll(rooms.expand((room) => room.imageGuids));

      await _data.deleteLocation(id);

      _imageDataService.deleteImages(imagesToBeDeleted);
    } catch (e, s) {
      _log.severe("Failed to delete location $id", e, s);
    }
  }

  // ---- internals -----------------------------------------------------------

  // Build list item with zero-I/O image refs for smooth scrolling.
  LocationListItem _toListItem(Location loc) {
    final guids = loc.imageGuids;
    final refs = _imageDataService.refsForGuids(guids);
    return LocationListItem(location: loc, images: refs);
  }
}
