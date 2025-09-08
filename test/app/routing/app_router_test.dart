// test/app/routing/app_router_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/app/routing/app_router.dart';
import 'package:stuff/app/routing/app_routes.dart';
import 'package:stuff/app/routing/app_routes_ext.dart';

import 'package:stuff/features/location/pages/locations_page.dart';
import 'package:stuff/features/location/pages/edit_location_page.dart';

import '../../utils/mocks.dart';
import '../../utils/ui_runner_helper.dart';
import '../../utils/dummies.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  // Map routes → expected page key
  final routePageKeys = <AppRoutes, Key>{
    // Locations
    AppRoutes.locations: const ValueKey('LocationsPage'),
    AppRoutes.locationAdd: const ValueKey('EditLocationPage'),
    AppRoutes.locationEdit: const ValueKey('EditLocationPage'),

    // Rooms
    AppRoutes.roomsForLocation: const ValueKey('RoomsPage'),
    AppRoutes.roomAdd: const ValueKey('EditRoomPage'),
    AppRoutes.roomEdit: const ValueKey('EditRoomPage'),

    // Containers
    AppRoutes.containerAddToRoom: const ValueKey('EditContainerPage'),
    AppRoutes.containerAddToContainer: const ValueKey('EditContainerPage'),
    AppRoutes.containerEdit: const ValueKey('EditContainerPage'),

    // Items (all go to ItemDetailsPage)
    AppRoutes.itemView: const ValueKey('ItemDetailsPage'),
    AppRoutes.itemEdit: const ValueKey('ItemDetailsPage'),
    AppRoutes.itemAddToRoom: const ValueKey('ItemDetailsPage'),
    AppRoutes.itemAddToContainer: const ValueKey('ItemDetailsPage'),

    // Contents
    AppRoutes.allContents: const ValueKey('ContentsPage'),
    AppRoutes.locationContents: const ValueKey('ContentsPage'),
    AppRoutes.roomContents: const ValueKey('ContentsPage'),
    AppRoutes.containerContents: const ValueKey('ContentsPage'),

    // Debug
    AppRoutes.debugDbInspector: const ValueKey('DatabaseInspectorPage'),
    AppRoutes.debugSampleDbRandomiser: const ValueKey('SampleDataOptionsPage'),
  };

  for (final route in AppRoutes.values.where((r) => !r.name.endsWith('Alias'))) {
    testWidgets('navigates to $route', (tester) async {
      // Example path params just to make the URL valid.
      final pathParams = <String, String>{
        'locationId': 'L1',
        'roomId': 'R1',
        'containerId': 'C1',
        'itemId': 'IT1',
      };

      final router = AppRouter.buildRouter(
        initialLocation: route.toUrlString(pathParams: pathParams),
      );

      await pumpAppWithMocks(
        tester,
        router: router,
        onMocksReady: (m) {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
        },
      );
      await tester.pumpAndSettle();

      final expectedKey = routePageKeys[route];
      expect(expectedKey, isNotNull, reason: 'Missing page key mapping for $route');
      expect(find.byKey(expectedKey!), findsOneWidget);
    });
  }

  test('buildRouter respects initialLocation (regression guard)', () {
    final router = AppRouter.buildRouter(initialLocation: '/items/XYZ');
    // This assertion fails if buildRouter ignores the parameter.
    expect(router.routeInformationProvider.value.uri.toString(), '/items/XYZ');
  });

  test('namedLocation builds expected path (locationsEdit)', () {
    final router = AppRouter.buildRouter();
    final path = router.namedLocation(
      AppRoutes.locationEdit.name,
      pathParameters: {'locationId': 'L1'},
    );
    expect(path, '/locations/L1/edit');
  });

  testWidgets('initial /locations renders without error (smoke)', (tester) async {
    final router = AppRouter.buildRouter(initialLocation: AppRoutes.locations.path);
    await pumpAppWithMocks(tester, router: router);
    await tester.pumpAndSettle();
    // Don’t assert on specific widget types if they need DI; just ensure no error page.
    expect(find.text('Error'), findsNothing);
  });

  testWidgets('nested item view redirects to canonical and preserves query', (tester) async {
    final router = AppRouter.buildRouter(
      initialLocation: AppRoutes.itemViewInRoomAlias.toUrlString(
        pathParams: {'locationId': 'L1', 'roomId': 'R1', 'itemId': 'IT1'},
        queryParams: {'tab': 'photos'},
      ),
    );

    await pumpAppWithMocks(tester, router: router);

    await tester.pumpAndSettle();

    // After redirect, the location should be canonical with the same query.
    expect(router.routeInformationProvider.value.uri.toString(), '/items/IT1?tab=photos');
  });

  testWidgets('unknown route shows errorBuilder page', (tester) async {
    final router = AppRouter.buildRouter(initialLocation: '/definitely-not-a-real-route');
    await pumpAppWithMocks(tester, router: router);

    await tester.pumpAndSettle();

    expect(find.text('Error'), findsOneWidget);
    expect(find.textContaining('Unknown navigation error', findRichText: true), findsNothing);
  });

  testWidgets('router.goNamed navigates to EditLocationPage', (tester) async {
    final router = AppRouter.buildRouter();

    await pumpAppWithMocks(
      tester,
      home: const SizedBox.shrink(),
      router: router,
      onMocksReady: (m) {
        when(
          m.temporaryFileService.startSession(label: anyNamed('label')),
        ).thenAnswer((_) async => MockTempSession());
      },
    );

    await tester.pumpAndSettle();

    // Initial route: /locations
    expect(find.byType(LocationsPage), findsOneWidget);

    // Navigate with the router directly
    router.goNamed(AppRoutes.locationAdd.name);
    await tester.pumpAndSettle();

    expect(find.byType(EditLocationPage), findsOneWidget);
  });
}
