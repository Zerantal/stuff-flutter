// test/features/item/pages/item_details_page_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stuff/app/routing/app_router.dart';
import 'package:stuff/app/routing/app_routes.dart';

import 'package:stuff/domain/models/item_model.dart';
import 'package:stuff/features/item/pages/item_details_page.dart';
import 'package:stuff/features/item/viewmodels/item_details_view_model.dart';
import 'package:stuff/shared/widgets/edit_entity_scaffold.dart';
import 'package:stuff/shared/widgets/initial_load_error_panel.dart';
import 'package:stuff/shared/widgets/loading_scaffold.dart';

import '../../../utils/mocks.dart';
import '../../../utils/ui_runner_helper.dart';

void main() {
  testWidgets('shows loading scaffold before init completes', (tester) async {
    final router = AppRouter.buildRouter(initialLocation: '/items/i1');

    final completer = Completer<Item>();

    await pumpAppWithMocks(
      tester,
      router: router,
      onMocksReady: (mocks) {
        when(mocks.dataService.getItemById('i1')).thenAnswer((_) => completer.future);
        when(
          mocks.temporaryFileService.startSession(label: anyNamed('label')),
        ).thenAnswer((_) async => MockTempSession());
      },
    );

    // Pump one frame only — don’t settle
    await tester.pump();
    expect(find.byType(LoadingScaffold), findsOneWidget);

    // Later: complete it
    completer.complete(
      Item(id: 'i1', roomId: 'r1', name: 'Test', description: '', imageGuids: const []),
    );

    await tester.pumpAndSettle();
    expect(find.byType(EditEntityScaffold), findsOneWidget);
  });

  testWidgets('shows error panel when init fails', (tester) async {
    final router = AppRouter.buildRouter(initialLocation: '/items/i1');

    await pumpAppWithMocks(
      tester,
      router: router,
      onMocksReady: (mocks) {
        when(mocks.dataService.getItemById('i1')).thenThrow(Exception('db fail'));
      },
    );

    await tester.pumpAndSettle();

    expect(find.byType(InitialLoadErrorPanel), findsOneWidget);
    expect(find.textContaining('Could not load item'), findsOneWidget);
  });

  testWidgets('shows details in view mode when init succeeds', (tester) async {
    final router = AppRouter.buildRouter(initialLocation: '/items/i1');

    await pumpAppWithMocks(
      tester,
      router: router,
      onMocksReady: (mocks) {
        when(mocks.dataService.getItemById('i1')).thenAnswer(
          (_) async => Item(
            id: 'i1',
            roomId: 'r1',
            name: 'Chair',
            description: 'Wooden chair',
            imageGuids: const [],
          ),
        );
      },
    );

    await tester.pumpAndSettle();

    expect(find.byType(EditEntityScaffold), findsOneWidget);
    expect(find.text('Chair'), findsOneWidget);
    expect(find.text('Wooden chair'), findsOneWidget);
  });

  testWidgets('navigating from view → edit flips VM into edit mode', (tester) async {
    final router = AppRouter.buildRouter(initialLocation: '/items/i1');

    await pumpAppWithMocks(
      tester,
      router: router,
      onMocksReady: (mocks) {
        when(mocks.dataService.getItemById('i1')).thenAnswer(
          (_) async => Item(
            id: 'i1',
            roomId: 'r1',
            name: 'Lamp',
            description: 'Desk lamp',
            imageGuids: const [],
          ),
        );
        when(mocks.dataService.getItemById('i1')).thenThrow(Exception('db fail'));
      },
    );

    await tester.pumpAndSettle();

    // Grab the real VM
    final vm = tester.element(find.byType(ItemDetailsPage)).read<ItemDetailsViewModel>();

    expect(vm.isEditable, isFalse);

    router.go('/items/i1/edit');
    await tester.pumpAndSettle();

    expect(vm.isEditable, isTrue);
  });

  testWidgets('retry after init failure loads item successfully', (tester) async {
    var failFirst = true;

    await pumpAppWithMocks(
      tester,
      router: AppRouter.buildRouter(initialLocation: '/items/i1'),
      onMocksReady: (mocks) {
        when(
          mocks.temporaryFileService.startSession(label: anyNamed('label')),
        ).thenAnswer((_) async => MockTempSession());
        when(mocks.dataService.getItemById('i1')).thenAnswer((_) async {
          if (failFirst) {
            failFirst = false;
            throw Exception('boom');
          }
          return Item(
            id: 'i1',
            roomId: 'r1',
            name: 'Recovered',
            description: 'ok',
            imageGuids: const [],
          );
        });
      },
    );

    await tester.pumpAndSettle();
    expect(find.byType(InitialLoadErrorPanel), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(EditEntityScaffold), findsOneWidget);
    expect(find.text('Recovered'), findsOneWidget);
  });

  group('ItemDetailsPage behaviours', () {
    testWidgets('retry after init failure loads item successfully', (tester) async {
      var failFirst = true;

      await pumpAppWithMocks(
        tester,
        router: AppRouter.buildRouter(initialLocation: '/items/i1'),
        onMocksReady: (mocks) {
          when(
            mocks.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          when(mocks.dataService.getItemById('i1')).thenAnswer((_) async {
            if (failFirst) {
              failFirst = false;
              throw Exception('boom');
            }
            return Item(
              id: 'i1',
              roomId: 'r1',
              name: 'Recovered',
              description: 'ok',
              imageGuids: const [],
            );
          });
        },
      );

      await tester.pumpAndSettle();
      expect(find.byType(InitialLoadErrorPanel), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(EditEntityScaffold), findsOneWidget);
      expect(find.text('Recovered'), findsOneWidget);
    });

    testWidgets('close after init failure pops the route', (tester) async {
      final router = AppRouter.buildRouter();

      await pumpAppWithMocks(
        tester,
        router: router,
        onMocksReady: (mocks) {
          when(
            mocks.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          when(mocks.dataService.getItemById('i1')).thenThrow(Exception('always fails'));
        },
      );
      router.pushNamed(AppRoutes.itemView.name, pathParameters: {'itemId': 'i1'});

      await tester.pumpAndSettle();
      expect(find.byType(InitialLoadErrorPanel), findsOneWidget);

      // Close button triggers maybePop
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Router should now be at root
      expect(router.routerDelegate.currentConfiguration.uri.toString(), AppRoutes.locations.path);
    });

    testWidgets('navigating view → edit → view flips VM isEditable', (tester) async {
      final router = AppRouter.buildRouter(initialLocation: '/items/i1');

      await pumpAppWithMocks(
        tester,
        router: router,
        onMocksReady: (mocks) {
          when(
            mocks.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          when(mocks.dataService.getItemById('i1')).thenAnswer(
            (_) async =>
                Item(id: 'i1', roomId: 'r1', name: 'ItemX', description: '', imageGuids: const []),
          );
        },
      );

      await tester.pumpAndSettle();

      final vm = tester.element(find.byType(ItemDetailsPage)).read<ItemDetailsViewModel>();
      expect(vm.isEditable, isFalse);

      router.go('/items/i1/edit');
      await tester.pumpAndSettle();
      expect(vm.isEditable, isTrue);

      router.go('/items/i1');
      await tester.pumpAndSettle();
      expect(vm.isEditable, isFalse);
    });

    testWidgets('unsaved changes guard shows confirmation dialog', (tester) async {
      final router = AppRouter.buildRouter();

      await pumpAppWithMocks(
        tester,
        router: router,
        onMocksReady: (mocks) {
          when(
            mocks.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          when(mocks.dataService.getItemById('i1')).thenAnswer(
            (_) async => Item(
              id: 'i1',
              roomId: 'r1',
              name: 'DirtyItem',
              description: '',
              imageGuids: const [],
            ),
          );
        },
      );
      router.pushNamed(AppRoutes.itemView.name, pathParameters: {'itemId': 'i1'});

      await tester.pumpAndSettle();

      final vm = tester.element(find.byType(ItemDetailsPage)).read<ItemDetailsViewModel>();
      vm.isEditable = true;
      vm.setDescription('Description change');
      await tester.pumpAndSettle();
      expect(vm.hasUnsavedChanges, isTrue);

      await tester.tap(find.byTooltip('Back')); // taps the Material AppBar back button
      await tester.pump();

      // Confirm dialog should appear
      expect(find.textContaining('Discard changes?'), findsOneWidget);
    });

    testWidgets('saving state disables form fields', (tester) async {
      final saveCompleter = Completer<Item>();

      await pumpAppWithMocks(
        tester,
        router: AppRouter.buildRouter(initialLocation: '/items/i1/edit'),
        onMocksReady: (mocks) {
          when(
            mocks.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          when(mocks.dataService.getItemById('i1')).thenAnswer(
            (_) async => Item(
              id: 'i1',
              roomId: 'r1',
              name: 'SavingItem',
              description: '',
              imageGuids: const [],
            ),
          );
          when(mocks.dataService.upsertItem(any)).thenAnswer((_) async => saveCompleter.future);
        },
      );

      await tester.pumpAndSettle();

      // Tap save button instead of calling vm directly
      await tester.tap(find.byKey(const ValueKey('save_entity_fab')));
      await tester.pump(); // let isSaving flip true

      // Expect that fields are now disabled
      final nameField = tester.widget<TextFormField>(find.byKey(const Key('item_name')));
      expect(nameField.enabled, isFalse);

      final descField = tester.widget<TextFormField>(find.byKey(const Key('item_description')));
      expect(descField.enabled, isFalse);

      // Complete the save
      saveCompleter.complete(
        Item(id: 'i1', roomId: 'r1', name: 'SavedItem', description: '', imageGuids: const []),
      );
      await tester.pumpAndSettle();

      // After save, fields should be enabled again
      final nameFieldAfter = tester.widget<TextFormField>(find.byKey(const Key('item_name')));
      expect(nameFieldAfter.enabled, isTrue);
    });

    testWidgets('new item shows Add Item title', (tester) async {
      await pumpAppWithMocks(
        tester,
        router: AppRouter.buildRouter(initialLocation: '/rooms/R1/items/add'),
        onMocksReady: (mocks) {
          when(
            mocks.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
        },
      );

      await tester.pumpAndSettle();
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('existing item shows item name in title', (tester) async {
      await pumpAppWithMocks(
        tester,
        router: AppRouter.buildRouter(initialLocation: '/items/i1'),
        onMocksReady: (mocks) {
          when(
            mocks.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          when(mocks.dataService.getItemById('i1')).thenAnswer(
            (_) async => Item(
              id: 'i1',
              roomId: 'r1',
              name: 'ExistingItem',
              description: '',
              imageGuids: const [],
            ),
          );
        },
      );

      await tester.pumpAndSettle();
      expect(find.text('ExistingItem'), findsOneWidget);
    });
  });
}
