// lib/services/geolocator_location_service.dart
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:stuff/services/permission_service_interface.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../wrappers/geolocator_wrapper.dart';
import '../wrappers/geocoding_wrapper.dart';
import '../wrappers/impl/geolocator_wrapper_impl.dart';
import '../wrappers/impl/geocoding_wrapper_impl.dart';
import '../impl/permission_handler_service.dart';
import '../location_service_interface.dart';
import '../exceptions/permission_exceptions.dart';
import '../exceptions/os_service_exceptions.dart';

final Logger _logger = Logger('GeolocatorLocationService');

class GeolocatorLocationService implements ILocationService {
  final IGeolocatorWrapper _geolocator;
  final IGeocodingWrapper _geocoding;
  final IPermissionService _permissionService;

  // Constructor for dependency injection
  GeolocatorLocationService({
    IGeolocatorWrapper? geolocator,
    IGeocodingWrapper? geocoding,
    IPermissionService? permissionService,
  }) : _geolocator = geolocator ?? GeolocatorWrapperImpl(),
       _geocoding = geocoding ?? GeocodingWrapperImpl(),
       _permissionService = permissionService ?? PermissionHandlerService();

  // This function should probably return 3 states:
  // denied, permitted, or denied but requestable
  @override
  Future<bool> isServiceEnabledAndPermitted() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logger.info("Location services are disabled.");
      return false;
    }

    permission = await _permissionService.checkLocationPermission();
    if (permission == LocationPermission.deniedForever) {
      _logger.info("Location permission permanently denied.");
      return false;
    }
    if (permission == LocationPermission.denied) {
      _logger.info("Location permission denied (but not permanently).");
      return false;
    }

    _logger.info("Location services enabled and permission granted.");
    return true;
  }

  @override
  Future<Position?> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) async {
    bool serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logger.warning('Location services are disabled on the device.');
      throw OSServiceDisabledException(
        serviceName: 'Location',
        message:
            'Location services are disabled. Please enable them in device settings.',
      );
    }

    LocationPermission permission = await _permissionService
        .checkLocationPermission();
    _logger.fine(
      "Initial permission status for getCurrentPosition: $permission",
    );

    if (permission == LocationPermission.denied) {
      _logger.info("Location permission is denied, requesting permission...");
      permission = await _permissionService.requestLocationPermission();
      _logger.info("Permission status after request: $permission");
      if (permission == LocationPermission.denied) {
        _logger.warning(
          'Location permission was denied by the user after request.',
        );
        throw LocationPermissionDeniedException(
          'Location permission was denied by the user.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _logger.warning('Location permissions are permanently denied.');
      throw LocationPermissionDeniedPermanentlyException(
        'Location permissions are permanently denied. Please enable them in the app settings.',
      );
    }

    // If we reach here, permissions should be granted (whileInUse or always)
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        _logger.info(
          "Attempting to get current position with accuracy: $desiredAccuracy",
        );

        final LocationSettings locationSettings = LocationSettings(
          accuracy: desiredAccuracy,
          timeLimit: const Duration(seconds: 15),
        );

        return await _geolocator
            .getCurrentPosition(locationSettings: locationSettings)
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () {
                _logger.warning(
                  'Timeout occurred while getting current position.',
                );
                throw TimeoutException(
                  'Could not get location in the allowed time. Please try again.',
                );
              },
            );
      } on TimeoutException {
        // Catch the timeout from the .timeout() extension specifically
        _logger.warning(
          'Caught TimeoutException from .timeout() while getting current position.',
        );
        throw TimeoutException(
          'Getting location timed out. Ensure you have a clear view of the sky or check network.',
        );
      } catch (e, s) {
        _logger.severe(
          'An unexpected error occurred in _geolocator.getCurrentPosition: $e',
          s,
        );
        throw Exception(
          'An unexpected error occurred while fetching location: $e',
        );
      }
    } else {
      // Should not be reached if logic above is correct, but as a fallback:
      _logger.severe(
        "Reached unexpected state in getCurrentPosition. Permission: $permission",
      );
      throw Exception("Unexpected permission state: $permission");
    }
  }

  @override
  Future<String?> getCurrentAddress() async {
    try {
      final Position? position = await getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      ); // Example: using bestForNavigation

      if (position == null) {
        // This case might be less likely if getCurrentPosition throws on failure
        // or times out, but good to handle.
        _logger.warning(
          "getCurrentPosition returned null without throwing an exception.",
        );
        return null;
      }

      _logger.fine(
        "Position for geocoding: Lat: ${position.latitude}, Lon: ${position.longitude}",
      );
      List<geocoding.Placemark> placemarks = await _geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final street = placemark.street ?? '';
        final subLocality = placemark.subLocality ?? '';
        final locality = placemark.locality ?? '';
        final postalCode = placemark.postalCode ?? '';
        final country = placemark.country ?? '';

        String formattedAddress = [
          street,
          subLocality,
          locality,
          postalCode,
          country,
        ].where((s) => s.isNotEmpty).join(', ');

        _logger.info("Formatted address: $formattedAddress");
        return formattedAddress.isNotEmpty ? formattedAddress : null;
      } else {
        _logger.info("No placemarks found for the current location.");
        return null; // No address found, but not an "error" state for permissions
      }
    } on OSServiceDisabledException {
      rethrow;
    } on LocationPermissionDeniedException {
      rethrow;
    } on LocationPermissionDeniedPermanentlyException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e, s) {
      _logger.severe(
        'Error during geocoding or other issue in getCurrentAddress: $e',
        s,
      );
      return null; // For now, returning null for non-permission/service related geocoding errors
    }
  }
}
