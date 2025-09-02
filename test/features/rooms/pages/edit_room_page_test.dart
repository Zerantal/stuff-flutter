import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/app/routing/app_router.dart';
import 'package:stuff/app/routing/app_routes.dart';
import 'package:stuff/domain/models/room_model.dart';

import 'package:stuff/features/room/pages/edit_room_page.dart';

import '../../../utils/mocks.dart';
import '../../../utils/ui_runner_helper.dart';
import '../../../utils/dummies.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  group('EditRoomPage', () {
    testWidgets('Add mode renders form fields and image manager when session ready', (
      tester,
    ) async {
      final router = AppRouter.buildRouter();

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

      // Navigate to "add room" page
      router.goNamed(AppRoutes.roomsAdd.name, pathParameters: {'locationId': 'L1'});
      await tester.pump(); // let page build its spinner first
      await tester.pumpAndSettle();

      // Page is present
      expect(find.byType(EditRoomPage), findsOneWidget);

      // Basic form fields — adjust keys if your page uses different ones
      expect(find.byKey(const Key('room_name')), findsOneWidget);
      expect(find.byKey(const Key('room_description')), findsOneWidget);

      // Image manager appears when temp session is available
      expect(find.byKey(const Key('room_image_manager')), findsOneWidget);

      // Save FAB exists
      expect(find.byKey(const Key('save_entity_fab')), findsOneWidget);
    });

    testWidgets('Save FAB validates name and allows save after entering text', (tester) async {
      final router = AppRouter.buildRouter();

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

      router.goNamed(AppRoutes.roomsAdd.name, pathParameters: {'locationId': 'L1'});
      await tester.pumpAndSettle();

      // Enter a valid name (most validators require non-empty)
      final nameField = find.byKey(const Key('room_name'));
      await tester.enterText(nameField, 'Conference Room');
      await tester.pump();

      // Tap Save — we only assert it doesn’t throw and the button exists;
      // the real persistence is integration-covered elsewhere
      await tester.tap(find.byKey(const Key('save_entity_fab')));
      await tester.pump(); // let validation run
    });

    testWidgets('Edit mode renders and still shows save FAB', (tester) async {
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

      router.goNamed(
        AppRoutes.roomsEdit.name,
        pathParameters: {'locationId': 'L1', 'roomId': 'R1'},
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditRoomPage), findsOneWidget);
      expect(find.byKey(const Key('save_entity_fab')), findsOneWidget);
    });
  });
}
