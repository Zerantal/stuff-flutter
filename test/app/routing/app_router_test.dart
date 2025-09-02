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

  test('buildRouter respects initialLocation (regression guard)', () {
    final router = AppRouter.buildRouter(initialLocation: '/items/XYZ');
    // This assertion fails if buildRouter ignores the parameter.
    expect(router.routeInformationProvider.value.uri.toString(), '/items/XYZ');
  });

  test('namedLocation builds expected path (locationsEdit)', () {
    final router = AppRouter.buildRouter();
    final path = router.namedLocation(
      AppRoutes.locationsEdit.name,
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

  testWidgets(skip: true, 'nested item view redirects to canonical and preserves query', (
    tester,
  ) async {
    final router = AppRouter.buildRouter(
      initialLocation: AppRoutes.itemViewInRoom.toUrlString(
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
    router.goNamed(AppRoutes.locationsAdd.name);
    await tester.pumpAndSettle();

    expect(find.byType(EditLocationPage), findsOneWidget);
  });
}
