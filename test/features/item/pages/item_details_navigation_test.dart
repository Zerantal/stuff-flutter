import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:stuff/app/routing/app_router.dart';
import 'package:stuff/domain/models/item_model.dart';
import 'package:stuff/features/item/pages/item_details_page.dart';
import 'package:stuff/features/item/viewmodels/item_details_view_model.dart';
import 'package:stuff/shared/widgets/edit_entity_scaffold.dart';
import 'package:stuff/shared/widgets/initial_load_error_panel.dart';

import '../../../utils/mocks.dart';
import '../../../utils/ui_runner_helper.dart';

void main() {
  testWidgets('navigating between view and edit keeps scaffold and toggles VM.isEditable', (
    tester,
  ) async {
    // Arrange: create mocks for services
    final mocks = TestAppMocks();

    // Stub dataService.getItemById
    when(mocks.dataService.getItemById('i1')).thenAnswer(
      (_) async => Item(
        id: 'i1',
        roomId: 'r1',
        name: 'Test Item',
        description: 'desc',
        imageGuids: const [],
      ),
    );
    when(
      mocks.temporaryFileService.startSession(label: anyNamed('label')),
    ).thenAnswer((_) async => MockTempSession());

    // Build the real router, starting in view mode
    final router = AppRouter.buildRouter(initialLocation: '/items/i1');

    await pumpApp(tester, router: router, providers: mocks.providers);

    // Wait for async load
    await tester.pumpAndSettle();
    await untilCalled(mocks.dataService.getItemById('i1'));

    // Grab the real VM from context
    final vm = tester.element(find.byType(ItemDetailsPage)).read<ItemDetailsViewModel>();

    // Verify initial state
    expect(vm.isEditable, isFalse);
    final scaffoldFinder = find.byType(EditEntityScaffold);
    expect(scaffoldFinder, findsOneWidget);

    final initialElement = tester.element(scaffoldFinder);

    // Act: navigate to edit route
    router.go('/items/i1/edit');
    await tester.pumpAndSettle();

    // Scaffold still present
    expect(scaffoldFinder, findsOneWidget);

    // Same scaffold element -> same instance
    final afterElement = tester.element(scaffoldFinder);
    expect(identical(initialElement, afterElement), isTrue);

    // VM should now be in edit mode
    expect(vm.isEditable, isTrue);

    // Act: navigate back to readonly
    router.go('/items/i1');
    await tester.pumpAndSettle();

    // Scaffold still present
    expect(scaffoldFinder, findsOneWidget);

    // VM should now be back to view-only
    expect(vm.isEditable, isFalse);
  });

  testWidgets('navigating to item with service failure shows InitialLoadErrorPanel', (
    tester,
  ) async {
    final mocks = TestAppMocks();

    // Stub failure
    when(mocks.dataService.getItemById('i1')).thenThrow(Exception('DB unavailable'));

    final router = AppRouter.buildRouter(initialLocation: '/items/i1');

    await pumpApp(tester, router: router, providers: mocks.providers);

    await tester.pumpAndSettle();

    // Assert: scaffold is NOT shown
    expect(find.byType(EditEntityScaffold), findsNothing);

    // Assert: error panel IS shown
    expect(find.byType(InitialLoadErrorPanel), findsOneWidget);
    expect(find.textContaining('Could not load item.'), findsOneWidget);

    // Grab VM and assert error set
    final vm = tester
        .element(find.byKey(const ValueKey('ItemDetailsPage')))
        .read<ItemDetailsViewModel>();
    expect(vm.initialLoadError, isNotNull);

    // Retry button exists
    expect(find.byKey(const ValueKey('initial_load_retry_btn')), findsOneWidget);
  });
}
