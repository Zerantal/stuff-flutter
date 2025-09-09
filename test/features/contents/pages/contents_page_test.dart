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
}
