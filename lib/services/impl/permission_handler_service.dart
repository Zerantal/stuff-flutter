// lib/services/impl/permission_handler_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../permission_service_interface.dart';

class PermissionHandlerService implements IPermissionService {
  @override
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  @override
  Future<bool> requestGalleryPermission() async {
    // For gallery, permission_handler uses Photos (iOS) and Storage (Android pre-SDK 33)
    // or specific media permissions (SDK 33+).
    var status = await Permission.photos.status;
    if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
      status = await Permission.photos.request();
    }

    return status.isGranted;
  }

  @override
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }
}
