// lib/services/permission_service_interface.dart
import 'package:geolocator/geolocator.dart';

abstract class IPermissionService {
  Future<bool> requestCameraPermission();

  Future<bool> requestGalleryPermission();

  Future<LocationPermission> checkLocationPermission();

  Future<LocationPermission> requestLocationPermission();
}
