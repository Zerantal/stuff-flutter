import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:stuff/app/routing/app_router.dart';

import 'package:stuff/app/routing/app_routes.dart';
import 'package:stuff/app/routing/app_routes_ext.dart';
import 'package:stuff/features/location/pages/edit_location_page.dart';
import 'package:stuff/features/location/pages/locations_page.dart';
import '../../utils/mocks.mocks.dart';
import '../../utils/test_router.dart';
import '../../utils/ui_runner_helper.dart';

Widget _wrap(GoRouter router) => MaterialApp.router(routerConfig: router);

void main() {
  group('AppRoutes.toUrlString', () {
    test('returns static path for routes without params', () {
      expect(AppRoutes.locations.toUrlString(), '/locations');
    });

    test('throws when required path param is missing', () {
      expect(() => AppRoutes.locationsEdit.toUrlString(), throwsA(isA<ArgumentError>()));
    });

    test('URL-encodes path params', () {
      // space and slash must be encoded
      final url = AppRoutes.rooms.toUrlString(pathParams: {'locationId': 'L 1/2'});
      expect(url, '/locations/L%201%2F2/rooms');
    });

    test('appends query parameters', () {
      final url = AppRoutes.locations.toUrlString(queryParams: {'filter': 'new', 'page': '2'});
      // order may vary—assert by contains
      expect(url, startsWith('/locations?'));
      expect(url.contains('filter=new'), isTrue);
      expect(url.contains('page=2'), isTrue);
    });

    test('formats path params', () {
      expect(
        AppRoutes.roomsEdit.toUrlString(pathParams: {'locationId': 'L1', 'roomId': 'R1'}),
        '/locations/L1/rooms/R1/edit',
      );
    });

    test('adds query params', () {
      final p = AppRoutes.rooms.toUrlString(
        pathParams: {'locationId': 'L1'},
        queryParams: {'q': 'kitchen', 'sort': 'asc'},
      );
      expect(p, '/locations/L1/rooms?q=kitchen&sort=asc');
    });

    test('throws when required param missing', () {
      expect(() => AppRoutes.roomsEdit.toUrlString(), throwsA(isA<ArgumentError>()));
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
      expect(loc, '/locations/L1/rooms');
    });

    testWidgets('AppRoutes.push (extension) navigates to EditLocationPage', (tester) async {
      final router = AppRouter.buildRouter();
      await pumpPageWithServices(
        tester,
        pageWidget: const SizedBox.shrink(),
        router: router,
        onMocksReady: (m) {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
        },
      );

      await tester.pumpAndSettle();

      // Initial route should be /locations
      expect(find.byType(LocationsPage), findsOneWidget);

      // Use the LocationsPage's context (Element implements BuildContext)
      final BuildContext ctx = tester.element(find.byType(LocationsPage));
      AppRoutes.locationsAdd.push(ctx);
      await tester.pumpAndSettle();

      expect(find.byType(EditLocationPage), findsOneWidget);
    });

    testWidgets('popAndPush removes EditLocationPage from the stack', (tester) async {
      final router = AppRouter.buildRouter();

      await pumpPageWithServices(
        tester,
        // a dummy root; router will drive pages
        pageWidget: const SizedBox.shrink(),
        router: router,
        onMocksReady: (m) {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
        },
      );

      await tester.pumpAndSettle();

      // We should start on /locations
      expect(find.byType(LocationsPage), findsOneWidget);

      // Push /locations/add (EditLocationPage)
      router.pushNamed(AppRoutes.locationsAdd.name);
      await tester.pumpAndSettle();
      expect(find.byType(EditLocationPage), findsOneWidget);

      // Call the extension under test: pop current then push Locations
      final ctx = tester.element(find.byType(EditLocationPage));
      AppRoutes.locations.popAndPush(ctx);
      await tester.pumpAndSettle();

      // Now stack is [Locations, Locations]; edit page is gone.
      expect(find.byType(EditLocationPage), findsNothing);
      expect(find.byType(LocationsPage), findsOneWidget);
      expect(router.canPop(), isTrue, reason: 'Two Locations pages on stack after popAndPush');

      // Go back once: if implementation was a plain push, we would land on EditLocationPage.
      router.pop();
      await tester.pumpAndSettle();

      // Correct (popAndPush): still on Locations, not on EditLocation.
      expect(find.byType(EditLocationPage), findsNothing);
      expect(find.byType(LocationsPage), findsOneWidget);

      // And now we are at the root again.
      expect(router.canPop(), isFalse);
    });

    testWidgets('CONTROL: a simple push leaves EditLocationPage beneath (bad behavior)', (
      tester,
    ) async {
      final router = AppRouter.buildRouter();

      await pumpPageWithServices(
        tester,
        pageWidget: const SizedBox.shrink(),
        router: router,
        onMocksReady: (m) {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
        },
      );

      await tester.pumpAndSettle();
      expect(find.byType(LocationsPage), findsOneWidget);

      // Push edit
      router.pushNamed(AppRoutes.locationsAdd.name);
      await tester.pumpAndSettle();
      expect(find.byType(EditLocationPage), findsOneWidget);

      // BAD scenario: replace popAndPush with a simple push to Locations
      router.pushNamed(AppRoutes.locations.name);
      await tester.pumpAndSettle();

      // Stack is [Locations, EditLocation, Locations]
      expect(router.canPop(), isTrue);

      // Pop once: we SHOULD reveal EditLocationPage here (demonstrates the bug)
      router.pop();
      await tester.pumpAndSettle();

      expect(
        find.byType(EditLocationPage),
        findsOneWidget,
        reason: 'Plain push reveals the edit page on back (bad)',
      );
    });
  });
}
