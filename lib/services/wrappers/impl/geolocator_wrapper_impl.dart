import 'package:geolocator/geolocator.dart';

import '../geolocator_wrapper.dart';

class GeolocatorWrapperImpl implements IGeolocatorWrapper {
  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    final settings =
        locationSettings ??
        const LocationSettings(accuracy: LocationAccuracy.high);
    return Geolocator.getCurrentPosition(locationSettings: settings);
  }
}
