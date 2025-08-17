import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stuff/app/routing/app_routes.dart';
import 'package:stuff/app/routing/app_route_ext.dart';
import '../../utils/test_router.dart';

Widget _wrap(GoRouter router) => MaterialApp.router(routerConfig: router);

void main() {
  group('AppRoutes.format', () {
    test('formats path params', () {
      expect(AppRoutes.roomsEdit.format(pathParams: {'roomId': 'R1'}), '/rooms/R1/edit');
    });

    test('adds query params', () {
      final p = AppRoutes.rooms.format(
        pathParams: {'locationId': 'L1'},
        queryParams: {'q': 'kitchen', 'sort': 'asc'},
      );
      expect(p, '/rooms/L1?q=kitchen&sort=asc');
    });

    test('throws when required param missing', () {
      expect(() => AppRoutes.roomsEdit.format(), throwsA(isA<ArgumentError>()));
    });

    test('items route requires {t, roomOrContainerId}', () {
      final p = AppRoutes.items.format(pathParams: {'t': 'room', 'roomOrContainerId': 'L1'});
      expect(p, '/items/room/L1');
    });
  });

  group('AppRouteNav navigation wrappers', () {
    testWidgets('go navigates to named route with params', (tester) async {
      final router = makeTestRouter(
        home: const SizedBox.shrink(),
        initialLocation: '/locations', // keep your starting point
      );
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();

      // Start on locations
      expect(find.byKey(const ValueKey('route_locations')), findsOneWidget);

      // Use the extension to navigate
      final ctx = tester.element(find.byType(Scaffold));
      AppRoutes.rooms.go(ctx, pathParams: {'locationId': 'L1'});
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route_rooms')), findsOneWidget);
    });

    testWidgets('push navigates to named route with params', (tester) async {
      final router = makeTestRouter(home: const SizedBox.shrink(), initialLocation: '/locations');
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(Scaffold));
      AppRoutes.roomsAdd.push(ctx, pathParams: {'locationId': 'L1'});
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route_roomsAdd')), findsOneWidget);
    });

    testWidgets('location(BuildContext) builds a namedLocation string', (tester) async {
      final router = makeTestRouter(home: const SizedBox.shrink(), initialLocation: '/locations');
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(Scaffold));
      final loc = AppRoutes.rooms.location(ctx, pathParams: {'locationId': 'L1'});
      expect(loc, '/rooms/L1');
    });
  });
}
