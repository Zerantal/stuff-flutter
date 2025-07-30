import 'package:geocoding/geocoding.dart' as geocoding;

import '../geocoding_wrapper.dart';

class GeocodingWrapperImpl implements IGeocodingWrapper {
  @override
  Future<List<geocoding.Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude,
  ) {
    return geocoding.placemarkFromCoordinates(latitude, longitude);
  }
}
