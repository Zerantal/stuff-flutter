import 'package:geocoding/geocoding.dart' as geocoding;

abstract class IGeocodingWrapper {
  Future<List<geocoding.Placemark>> placemarkFromCoordinates(double latitude, double longitude);
}
