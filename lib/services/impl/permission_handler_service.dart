// lib/services/impl/permission_handler_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';

import '../permission_service_interface.dart';

final Logger _logger = Logger('PermissionHandlerService');

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
    // The permission_handler plugin handles platform differences for Permission.photos.
    // On Android, Permission.photos typically maps to:
    // - READ_EXTERNAL_STORAGE (for older Android versions)
    // - READ_MEDIA_IMAGES (for Android 13+)
    // - It also handles the "Selected Photos" access on Android 14+.
    var status = await Permission.photos.status;
    _logger.info("Initial gallery/photos status: $status");

    // When to proceed:
    // 1. Already granted: User has given full access.
    // 2. Limited: User has selected specific photos (iOS, or Android 14+ "Selected Photos" equivalent).
    //    In this state, the native picker will correctly show only the allowed photos.
    if (status.isGranted || status.isLimited) {
      _logger.info("Gallery/photos permission is sufficient (granted or limited). Proceeding.");
      return true; // Sufficient permission to proceed with image_picker
    }

    // If denied, restricted, or permanently denied, then request.
    // Requesting again when it's 'limited' on iOS might allow the user to change their selection,
    // which can be a valid UX if you want to offer that explicitly.
    // However, for simply picking an image, 'limited' is enough to proceed.
    _logger.info("Gallery/photos permission is not sufficient ($status). Requesting...");
    status = await Permission.photos.request();
    _logger.info("Status after gallery/photos request: $status");

    return (status.isGranted || status.isLimited);
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
