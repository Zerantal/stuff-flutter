// lib/features/shared/edit/geolocate_mixin.dart

// GeolocateMixin<T>
// - Wraps ILocationService.getDeviceLocation()
// - Lets you toggle a "busy" flag and apply the resolved address/coords
//
// Provide small closures to read/write your state; no assumptions about T.

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../../../services/contracts/location_service_interface.dart';

final Logger _log = Logger('GeolocateMixin');

mixin GeolocateMixin on ChangeNotifier {
  late ILocationService _locationService;

  bool _isGettingLocation = false;
  bool _deviceHasLocationService = true; // optimistic default

  @protected
  void configureGeolocate({required ILocationService locationService}) {
    _locationService = locationService;
  }

  // ---------------------------------------------------------------------------
  // Public surface
  // ---------------------------------------------------------------------------

  bool get isGettingLocation => _isGettingLocation;
  bool get deviceHasLocationService => _deviceHasLocationService;

  /// Resolve current address.
  /// Returns true on success (non-empty address), false otherwise.
  ///
  /// NOTE: Implement `onAcquiredAddress` WITHOUT calling notifyListeners.
  /// The mixin will notify at the end.
  Future<bool> acquireCurrentAddress({bool notifyAtStart = true}) async {
    if (_isGettingLocation) return false;

    _isGettingLocation = true;
    _deviceHasLocationService = true; // reset optimistic state
    if (notifyAtStart) notifyListeners(); // show spinner ASAP

    var ok = false;
    try {
      final addr = await _locationService.getCurrentAddress();
      ok = addr != null && addr.trim().isNotEmpty;
      if (ok) {
        onAcquiredAddress(addr.trim()); // DO NOT notify here
      } else {
        _log.warning('getCurrentAddress returned null/empty');
      }
    } catch (e, s) {
      _log.severe('getCurrentAddress failed', e, s);
      _deviceHasLocationService = false;
    } finally {
      _isGettingLocation = false;
      notifyListeners();
    }
    return ok;
  }

  // ---------------------------------------------------------------------------
  // Hooks to override/implement in VM
  // ---------------------------------------------------------------------------

  /// update vm: no notify required
  @protected
  void onAcquiredAddress(String address);
}
