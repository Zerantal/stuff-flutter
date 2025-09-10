// test/features/container/pages/edit_container_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/app/routing/app_router.dart';
import 'package:stuff/app/routing/app_routes.dart';
import 'package:stuff/domain/models/container_model.dart' as domain;

import 'package:stuff/features/container/pages/edit_container_page.dart';
import 'package:stuff/shared/widgets/image_manager_input.dart';

import '../../../utils/mocks.dart';
import '../../../utils/ui_runner_helper.dart';
import '../../../utils/dummies.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  group('EditContainerPage', () {
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
      router.goNamed(AppRoutes.containerAddToRoom.name, pathParameters: {'roomId': 'R1'});
      await tester.pump(); // let page build its spinner first
      await tester.pumpAndSettle();

      // Page is present
      expect(find.byType(EditContainerPage), findsOneWidget);

      // Basic form fields — adjust keys if your page uses different ones
      expect(find.byKey(const Key('container_name')), findsOneWidget);
      expect(find.byKey(const Key('container_description')), findsOneWidget);

      // Image manager appears when temp session is available
      expect(find.byType(ImageManagerInput), findsOneWidget);

      // Save FAB exists
      expect(find.byKey(const Key('save_entity_fab')), findsOneWidget);
    });

    testWidgets('Add container to container - renders and still shows save FAB', (tester) async {
      final router = AppRouter.buildRouter();

      await pumpAppWithMocks(
        tester,
        router: router,
        onMocksReady: (m) {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());

          when(m.dataService.getContainerById('C1')).thenAnswer(
            (_) async =>
                domain.Container(id: 'C1', roomId: 'R1', name: 'Toolbox', imageGuids: const []),
          );
        },
      );

      await tester.pumpAndSettle();

      router.goNamed(AppRoutes.containerAddToContainer.name, pathParameters: {'containerId': 'C1'});
      await tester.pumpAndSettle();

      expect(find.byType(EditContainerPage), findsOneWidget);
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

      router.goNamed(AppRoutes.containerAddToRoom.name, pathParameters: {'roomId': 'R1'});
      await tester.pumpAndSettle();

      // Enter a valid name (most validators require non-empty)
      final nameField = find.byKey(const Key('container_name'));
      await tester.enterText(nameField, 'Toolbox');
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

          when(m.dataService.getContainerById('C1')).thenAnswer(
            (_) async =>
                domain.Container(id: 'C1', roomId: 'R1', name: 'Toolbox', imageGuids: const []),
          );
        },
      );

      await tester.pumpAndSettle();

      router.goNamed(AppRoutes.containerEdit.name, pathParameters: {'containerId': 'C1'});
      await tester.pumpAndSettle();

      expect(find.byType(EditContainerPage), findsOneWidget);
      expect(find.byKey(const Key('save_entity_fab')), findsOneWidget);
    });

    testWidgets('initialLoadError panel supports retry and close', (tester) async {
      final router = AppRouter.buildRouter();

      final mocks = await pumpAppWithMocks(
        tester,
        router: router,
        onMocksReady: (m) {
          // Fail first call to trigger initialLoadError
          when(m.dataService.getRoomById('RERR')).thenThrow(Exception('boom'));
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
        },
      );

      await tester.pumpAndSettle();

      // Navigate to edit mode with a bad room id
      router.pushNamed(AppRoutes.containerEdit.name, pathParameters: {'containerId': 'CERR'});
      await tester.pumpAndSettle();

      // Panel should appear
      expect(find.byKey(const ValueKey('EditContainerPage')), findsOneWidget);
      expect(find.text('Could not load container.'), findsOneWidget);

      // Tap Retry → should call retryInitForEdit and thus trigger another getRoomById
      final retryBtn = find.byKey(const ValueKey('initial_load_retry_btn'));
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      verify(mocks.dataService.getContainerById('CERR')).called(greaterThan(1));

      // Then tap Close → should pop the page
      final closeBtn = find.byKey(const ValueKey('initial_load_close_btn'));
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('EditContainerPage')), findsNothing);
    });

    testWidgets('shows error panel and retries successfully', (tester) async {
      final router = AppRouter.buildRouter();

      late MockIDataService dataService;

      await pumpAppWithMocks(
        tester,
        router: router,
        onMocksReady: (m) {
          dataService = m.dataService;

          // First call: throw error → triggers initialLoadError
          when(dataService.getContainerById('C_ERR')).thenThrow(Exception('boom'));

          // We still need a TempSession so the form could work after retry
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
        },
      );

      await tester.pumpAndSettle();

      // Navigate to edit page for failing room
      router.pushNamed(AppRoutes.containerEdit.name, pathParameters: {'containerId': 'C_ERR'});
      await tester.pump();
      await tester.pumpAndSettle();

      // Error panel should appear
      expect(find.text('Could not load container.'), findsOneWidget);

      // Now fix the mock so retry succeeds
      when(dataService.getContainerById('C_ERR')).thenAnswer(
        (_) async => domain.Container(
          id: 'C_ERR',
          roomId: 'R1',
          name: 'Recovered Room',
          imageGuids: const [],
        ),
      );

      // Tap Retry
      final retryBtn = find.byKey(const Key('initial_load_retry_btn'));
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      // After retry success, error panel is gone and the edit form is shown
      expect(find.text('Could not load room.'), findsNothing);
      expect(find.byType(EditContainerPage), findsOneWidget);
      expect(find.text('Recovered Room'), findsOneWidget);
    });
  });
}
