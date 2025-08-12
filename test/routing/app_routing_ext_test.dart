import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/app/routing/app_routes.dart';
import 'package:stuff/app/routing/app_route_ext.dart';

void main() {
  group('AppRoute.format', () {
    test('returns static path for routes without params', () {
      expect(AppRoutes.locations.format(), '/locations');
    });

    test('throws when required path param is missing', () {
      expect(() => AppRoutes.locationsEdit.format(), throwsA(isA<ArgumentError>()));
    });

    test('substitutes required path param', () {
      final url = AppRoutes.locationsEdit.format(pathParams: {'locationId': '123'});
      expect(url, '/locations/123/edit');
    });

    test('URL-encodes path params', () {
      // space and slash must be encoded
      final url = AppRoutes.rooms.format(pathParams: {'locationId': 'L 1/2'});
      expect(url, '/rooms/L%201%2F2');
    });

    test('appends query parameters', () {
      final url = AppRoutes.locations.format(queryParams: {'filter': 'new', 'page': '2'});
      // order may vary—assert by contains
      expect(url, startsWith('/locations?'));
      expect(url.contains('filter=new'), isTrue);
      expect(url.contains('page=2'), isTrue);
    });
  });
}
