import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/contents/pages/contents_page.dart';
import 'package:stuff/features/contents/viewmodels/contents_view_model.dart';
import 'package:stuff/domain/models/container_model.dart' as dm;
import 'package:stuff/domain/models/item_model.dart' as dm;
import 'package:stuff/shared/widgets/empty_list_state.dart';

import '../../../utils/ui_runner_helper.dart';
import '../../../utils/dummies.dart';
import '../../../utils/test_router.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  Future<PumpedPlainVm<ContentsViewModel>> pump(
    WidgetTester tester, {
    ContentsScope scope = const ContentsScope.all(),
    required Stream<List<dm.Container>> containers,
    required Stream<List<dm.Item>> items,
  }) {
    final router = makeTestRouter(home: const ContentsPage());

    return pumpWithPlainVm<ContentsViewModel>(
      tester,
      home: const ContentsPage(),
      router: router,
      vmFactory: (mocks) {
        // Stub IDataService to produce given streams
        when(mocks.dataService.watchAllContainers()).thenAnswer((_) => containers);
        when(mocks.dataService.watchAllItems()).thenAnswer((_) => items);
        when(mocks.dataService.watchRoomContainers(any)).thenAnswer((_) => containers);
        when(mocks.dataService.watchRoomItems(any)).thenAnswer((_) => items);
        when(mocks.dataService.watchChildContainers(any)).thenAnswer((_) => containers);
        when(mocks.dataService.watchContainerItems(any)).thenAnswer((_) => items);
        when(mocks.dataService.runInTransaction(any)).thenAnswer((invocation) {
          final action = invocation.positionalArguments[0] as Future Function();
          return action();
        });
        return ContentsViewModel(
          dataService: mocks.dataService,
          imageDataService: mocks.imageDataService,
          scope: scope,
        );
      },
    );
  }

  testWidgets('shows empty state when no containers or items', (tester) async {
    await pump(tester, containers: Stream.value([]), items: Stream.value([]));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyListState), findsOneWidget);
  });

  testWidgets('renders containers section when containers exist', (tester) async {
    final container = dm.Container(id: 'C1', roomId: 'R1', name: 'Crate', imageGuids: ['g1']);
    await pump(tester, containers: Stream.value([container]), items: Stream.value([]));
    await tester.pumpAndSettle();

    expect(find.text('Containers'), findsOneWidget);
    expect(find.text('Crate'), findsOneWidget);
  });

  testWidgets('renders items section when items exist', (tester) async {
    final item = dm.Item(
      id: 'I1',
      roomId: 'R1',
      name: 'Hammer',
      description: 'A tool',
      imageGuids: ['i1'],
    );
    await pump(tester, containers: Stream.value([]), items: Stream.value([item]));
    await tester.pumpAndSettle();

    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Hammer'), findsOneWidget);
    expect(find.text('A tool'), findsOneWidget);
  });

  testWidgets('item body shows subtitle only when non-empty', (tester) async {
    final itemWithSubtitle = dm.Item(
      id: 'I1',
      roomId: 'R1',
      name: 'Hammer',
      description: 'A tool',
      imageGuids: [],
    );
    final itemWithoutSubtitle = dm.Item(
      id: 'I2',
      roomId: 'R1',
      name: 'Nail',
      description: '',
      imageGuids: [],
    );

    await pump(
      tester,
      containers: Stream.value([]),
      items: Stream.value([itemWithSubtitle, itemWithoutSubtitle]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hammer'), findsOneWidget);
    expect(find.text('A tool'), findsOneWidget);

    expect(find.text('Nail'), findsOneWidget);
    // no subtitle for Nail
    expect(find.text(''), findsNothing);
  });

  group('FAB visibility and actions', () {
    testWidgets('no FAB for AllScope', (tester) async {
      await pump(
        tester,
        scope: const ContentsScope.all(),
        containers: Stream.value([]),
        items: Stream.value([]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('no FAB for LocationScope', (tester) async {
      await pump(
        tester,
        scope: const ContentsScope.location('L1'),
        containers: Stream.value([]),
        items: Stream.value([]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('FAB for RoomScope shows container + item options', (tester) async {
      await pump(
        tester,
        scope: const ContentsScope.room('R1'),
        containers: Stream.value([]),
        items: Stream.value([]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      // open popup menu
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Container'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('FAB for ContainerScope shows sub-container + item options', (tester) async {
      await pump(
        tester,
        scope: const ContentsScope.container('C1'),
        containers: Stream.value([]),
        items: Stream.value([]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      // open popup menu
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Sub-Container'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });
  });

  group('FAB routing', () {
    testWidgets('RoomScope → Add Container routes to containerAddToRoom', (tester) async {
      await pump(
        tester,
        scope: const ContentsScope.room('R1'),
        containers: Stream.value([]),
        items: Stream.value([]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Container'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route_containerAddToRoom')), findsOneWidget);
    });

    testWidgets('RoomScope → Add Item routes to itemAddToRoom', (tester) async {
      await pump(
        tester,
        scope: const ContentsScope.room('R1'),
        containers: Stream.value([]),
        items: Stream.value([]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route_itemAddToRoom')), findsOneWidget);
    });

    testWidgets('ContainerScope → Add Sub-Container routes to containerAddToContainer', (
      tester,
    ) async {
      await pump(
        tester,
        scope: const ContentsScope.container('C1'),
        containers: Stream.value([]),
        items: Stream.value([]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Sub-Container'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route_containerAddToContainer')), findsOneWidget);
    });

    testWidgets('ContainerScope → Add Item routes to itemAddToContainer', (tester) async {
      await pump(
        tester,
        scope: const ContentsScope.container('C1'),
        containers: Stream.value([]),
        items: Stream.value([]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route_itemAddToContainer')), findsOneWidget);
    });
  });

  group('delete confirmation workflow', () {
    testWidgets('container delete workflow - confirm deletes and shows snackbar', (tester) async {
      final container = dm.Container(id: 'C1', roomId: 'R1', name: 'Box', imageGuids: const []);

      final vmData = await pump(
        tester,
        scope: const ContentsScope.room('R1'),
        containers: Stream.value([container]),
        items: Stream.value([]),
      );

      final dataService = vmData.mocks.dataService;

      // when(dataService.watchRoomContainers('R1')).thenAnswer((_) => Stream.value([container]));
      // when(dataService.watchRoomItems('R1')).thenAnswer((_) => Stream.value([]));
      when(dataService.getContainerById('C1')).thenAnswer((_) async => container);
      when(dataService.deleteContainer('C1')).thenAnswer((_) async {});

      await tester.pumpAndSettle();

      // Open context menu
      await tester.tap(find.byKey(const Key('context_action_menu')));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byKey(const ValueKey('delete_btn')));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.byKey(const ValueKey('conf_dialog_confirm_btn')));
      await tester.pumpAndSettle();

      verify(dataService.deleteContainer('C1')).called(1);
      expect(find.text('Container deleted'), findsOneWidget);
    });

    testWidgets('item delete workflow → confirm deletes and shows snackbar', (tester) async {
      final item = dm.Item(
        id: 'I1',
        roomId: 'R1',
        name: 'Hammer',
        description: 'A tool',
        imageGuids: const [],
      );

      final vmData = await pump(
        tester,
        scope: const ContentsScope.room('R1'),
        containers: Stream.value([]),
        items: Stream.value([item]),
      );

      final dataService = vmData.mocks.dataService;

      when(dataService.getItemById('I1')).thenAnswer((_) async => item);
      when(dataService.deleteItem('I1')).thenAnswer((_) async {});

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('context_action_menu')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('delete_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('conf_dialog_confirm_btn')));
      await tester.pumpAndSettle();

      verify(dataService.deleteItem('I1')).called(1);
      expect(find.text('Item deleted'), findsOneWidget);
    });

    testWidgets('cancel in delete dialog does not delete container', (tester) async {
      final container = dm.Container(id: 'C2', roomId: 'R1', name: 'Crate', imageGuids: const []);

      final vmData = await pump(
        tester,
        scope: const ContentsScope.room('R1'),
        containers: Stream.value([container]),
        items: Stream.value([]),
      );

      final data = vmData.mocks.dataService;

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('context_action_menu')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('delete_btn')));
      await tester.pumpAndSettle();

      // Cancel delete
      await tester.tap(find.byKey(const ValueKey('conf_dialog_cancel_btn')));
      await tester.pumpAndSettle();

      verifyNever(data.deleteContainer(any));
      expect(find.text('Container deleted'), findsNothing);
    });
  });
}
