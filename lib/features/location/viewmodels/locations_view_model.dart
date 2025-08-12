// lib/features/location/viewmodels/locations_view_model.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../shared/image/image_ref.dart';
import '../../../domain/models/location_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/sample_data_populator.dart';

final Logger _log = Logger('LocationsViewModel');

/// Simple DTO the UI can render directly.
class LocationListItem {
  final Location location;
  final ImageRef? image; // null => placeholder in the view
  const LocationListItem({required this.location, required this.image});
}

class LocationsViewModel with ChangeNotifier {
  LocationsViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
  }) : _data = dataService,
       _imageDataService = imageDataService {
    // Map the domain stream to UI-ready items without doing any I/O verification.
    locations = _data.getLocationsStream().asyncMap(_attachLeadImages);
    _log.fine('Subscribed to locations stream');
  }

  final IDataService _data;
  final IImageDataService _imageDataService;

  late final Stream<List<LocationListItem>>? locations;

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

  // ---- internals -----------------------------------------------------------

  /// Produces UI items with a best-effort image ref:
  /// - If there is no image GUID, we return null (view shows placeholder).
  /// - If there is a GUID, we ask the image service for a ref *without* verifying existence.
  ///   Any errors from the service turn into null so the view can show its error/placeholder.
  Future<List<LocationListItem>> _attachLeadImages(List<Location> locations) async {
    return Future.wait(
      locations.map((l) async {
        final guid = l.images.isNotEmpty ? l.images.first : null;
        if (guid == null) return LocationListItem(location: l, image: null);

        try {
          // IMPORTANT: no existence verification; just return a handle.
          final img = await _imageDataService.getImage(guid, verifyExists: false);
          return LocationListItem(location: l, image: img);
        } catch (e, s) {
          _log.warning('Image ref build failed for guid=$guid', e, s);
          return LocationListItem(location: l, image: null);
        }
      }),
    );
  }
}
