import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/contents/pages/contents_page.dart';
import 'package:stuff/features/contents/viewmodels/contents_view_model.dart';
import 'package:stuff/domain/models/container_model.dart' as dm;
import 'package:stuff/domain/models/item_model.dart' as dm;
import 'package:stuff/shared/widgets/empty_list_state.dart';

import '../../../utils/ui_runner_helper.dart';
import '../../../utils/dummies.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  Future<PumpedPlainVm<ContentsViewModel>> pump(
    WidgetTester tester, {
    required Stream<List<dm.Container>> containers,
    required Stream<List<dm.Item>> items,
  }) {
    return pumpWithPlainVm<ContentsViewModel>(
      tester,
      home: const ContentsPage(),
      vmFactory: (mocks) {
        // Stub IDataService to produce given streams
        when(mocks.dataService.watchAllContainers()).thenAnswer((_) => containers);
        when(mocks.dataService.watchAllItems()).thenAnswer((_) => items);
        return ContentsViewModel(
          dataService: mocks.dataService,
          imageDataService: mocks.imageDataService,
          scope: const ContentsScope.all(),
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
}
