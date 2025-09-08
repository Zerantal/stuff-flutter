import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/app/routing/app_router.dart';
import 'package:stuff/app/routing/app_routes.dart';
import 'package:stuff/domain/models/room_model.dart';

import 'package:stuff/features/room/pages/rooms_page.dart';
import 'package:stuff/features/room/pages/edit_room_page.dart';

import '../../../utils/mocks.dart';
import '../../../utils/ui_runner_helper.dart';
import '../../../utils/dummies.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  testWidgets('router.goNamed navigates to RoomsPage, then to EditRoomPage (add)', (tester) async {
    final router = AppRouter.buildRouter();

    await pumpAppWithMocks(
      tester,
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
    router.goNamed(AppRoutes.roomsForLocation.name, pathParameters: {'locationId': 'L1'});
    await tester.pumpAndSettle();

    expect(find.byType(RoomsPage), findsOneWidget);

    // Now navigate to add room page
    router.goNamed(AppRoutes.roomAdd.name, pathParameters: {'locationId': 'L1'});
    await tester.pumpAndSettle();

    expect(find.byType(EditRoomPage), findsOneWidget);
  });

  testWidgets('router.goNamed navigates to EditRoomPage (edit existing room)', (tester) async {
    final router = AppRouter.buildRouter();

    await pumpAppWithMocks(
      tester,
      router: router,
      onMocksReady: (m) {
        when(
          m.temporaryFileService.startSession(label: anyNamed('label')),
        ).thenAnswer((_) async => MockTempSession());

        when(m.dataService.getRoomById('R1')).thenAnswer(
          (_) async => Room(id: 'R1', locationId: 'L1', name: 'Room 1', imageGuids: const []),
        );
      },
    );

    await tester.pumpAndSettle();

    router.goNamed(AppRoutes.roomEdit.name, pathParameters: {'locationId': 'L1', 'roomId': 'R1'});
    await tester.pumpAndSettle();

    expect(find.byType(EditRoomPage), findsOneWidget);
  });
}
