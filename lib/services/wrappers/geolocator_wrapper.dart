import 'package:geolocator/geolocator.dart';

abstract class IGeolocatorWrapper {
  Future<bool> isLocationServiceEnabled();

  Future<Position> getCurrentPosition({LocationSettings? locationSettings});
}
