// lib/services/geolocator_location_service.dart
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

final Logger _logger = Logger('GeolocatorLocationService');

class GeolocatorLocationService implements ILocationService {
  final IGeolocatorWrapper _geolocator;
  final IGeocodingWrapper _geocoding;
  final IPermissionService _permissionService;

  // Constructor for dependency injection
  // Provide default real implementations if none are given (useful for production)
  GeolocatorLocationService({
    IGeolocatorWrapper? geolocator,
    IGeocodingWrapper? geocoding,
    IPermissionService? permissionService,
  }) : _geolocator = geolocator ?? GeolocatorWrapperImpl(),
       _geocoding = geocoding ?? GeocodingWrapperImpl(),
       _permissionService = permissionService ?? PermissionHandlerService();

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
    try {
      final bool hasPermission = await isServiceEnabledAndPermitted();
      if (!hasPermission) {
        // Try to request permission if simply denied (not permanently)
        LocationPermission permission = await _permissionService
            .checkLocationPermission();
        if (permission == LocationPermission.denied) {
          permission = await _permissionService.requestLocationPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _logger.warning(
            "Attempted to get position without sufficient permission.",
          );
          throw Exception(
            'Location permission not granted or service disabled.',
          );
        }
      }
      return await _geolocator.getCurrentPosition();
    } catch (e, s) {
      _logger.severe('Error getting current position: $e', s);
      rethrow;
    }
  }

  @override
  Future<String?> getCurrentAddress() async {
    try {
      final Position? position = await getCurrentPosition();
      if (position == null) {
        return null; // Could not get position
      }

      List<geocoding.Placemark> placemarks = await _geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // Construct a readable address - customize as needed
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
        return formattedAddress.isNotEmpty ? formattedAddress : null;
      } else {
        _logger.info("No placemarks found for the current location.");
        return null;
      }
    } catch (e, s) {
      _logger.severe('Error getting current address: $e', s);
      if (e is Exception &&
          e.toString().contains('Location permission not granted')) {
        rethrow;
      }
      return null; // For other geocoding errors, return null
    }
  }
}
