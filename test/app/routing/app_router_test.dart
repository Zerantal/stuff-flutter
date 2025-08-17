import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/app/routing/app_router.dart';
import 'package:stuff/app/routing/app_routes.dart';

import 'package:stuff/features/location/pages/locations_page.dart';
import 'package:stuff/features/location/pages/edit_location_page.dart';

import '../../utils/mocks.dart';
import '../../utils/ui_runner_helper.dart';
import '../../utils/dummies.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  test('namedLocation builds expected path (locationsEdit)', () {
    final router = AppRouter.buildRouter();
    final path = router.namedLocation(
      AppRoutes.locationsEdit.name,
      pathParameters: {'locationId': 'L1'},
    );
    expect(path, '/locations/L1/edit');
  });

  testWidgets('router.goNamed navigates to EditLocationPage', (tester) async {
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

    // Initial route: /locations
    expect(find.byType(LocationsPage), findsOneWidget);

    // Navigate with the router directly
    router.goNamed(AppRoutes.locationsAdd.name);
    await tester.pumpAndSettle();

    expect(find.byType(EditLocationPage), findsOneWidget);
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

    // Use the extension; needs a BuildContext
    tester.element(find.byType(Scaffold));
    router.goNamed(AppRoutes.locationsAdd.name);
    await tester.pumpAndSettle();

    expect(find.byType(EditLocationPage), findsOneWidget);
  });
}
