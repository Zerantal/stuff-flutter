import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/app/routing/app_router.dart';
import 'package:stuff/app/routing/app_routes.dart';

import 'package:stuff/features/room/pages/rooms_page.dart';
import 'package:stuff/features/room/pages/edit_room_page.dart';

import '../../../utils/mocks.dart';
import '../../../utils/ui_runner_helper.dart';
import '../../../utils/dummies.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  testWidgets('router.goNamed navigates to RoomsPage, then to EditRoomPage (add)',
          (tester) async {
        final router = AppRouter.buildRouter();

        await pumpPageWithServices(
          tester,
          pageWidget: const SizedBox.shrink(),
          router: router,
          // stub any services needed by EditRoomPage so its ImageManager can render
          onMocksReady: (m) {
            when(
              m.temporaryFileService.startSession(label: anyNamed('label')),
            ).thenAnswer((_) async => MockTempSession());
          },
        );

        await tester.pumpAndSettle();

        // Initial route: /locations (from AppRouter)
        // Navigate to Rooms for a location
        router.goNamed(AppRoutes.rooms.name, pathParameters: {'locationId': 'L1'});
        await tester.pumpAndSettle();

        expect(find.byType(RoomsPage), findsOneWidget);

        // Now navigate to add room page
        router.goNamed(AppRoutes.roomsAdd.name, pathParameters: {'locationId': 'L1'});
        await tester.pumpAndSettle();

        expect(find.byType(EditRoomPage), findsOneWidget);
      });

  testWidgets('router.goNamed navigates to EditRoomPage (edit existing room)',
          (tester) async {
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

        router.goNamed(
          AppRoutes.roomsEdit.name,
          pathParameters: {'locationId': 'L1', 'roomId': 'R1'},
        );
        await tester.pumpAndSettle();

        expect(find.byType(EditRoomPage), findsOneWidget);
      });
}
