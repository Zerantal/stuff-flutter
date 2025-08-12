// lib/services/contracts/location_service_interface.dart
import 'package:geolocator/geolocator.dart';

abstract class ILocationService {
  Future<bool> isServiceEnabledAndPermitted();
  Future<Position?> getCurrentPosition();
  Future<String?> getCurrentAddress();
}
