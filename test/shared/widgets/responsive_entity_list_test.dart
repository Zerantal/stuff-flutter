// test/shared/widgets/responsive_entity_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/responsive_entity_list.dart';
import 'package:stuff/shared/widgets/entity_item.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('ResponsiveEntityList', () {
    testWidgets('renders LIST when width < breakpoint', (tester) async {
      await _setSurfaceSize(tester, const Size(600, 800));
      final items = [1, 2, 3];

      await tester.pumpWidget(_app(ResponsiveEntityList<int>(
        items: items,
        gridBreakpoint: 720,
        thumbnailBuilder: (c, i) => Text('thumb $i'),
        descriptionBuilder: (c, i) => Text('desc $i'),
      )));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(EntityListItem), findsNWidgets(3));
      expect(find.text('desc 1'), findsOneWidget);
      // default separators (N-1)
      expect(find.byType(Divider), findsNWidgets(2));
      // list item keyed by ValueKey(item)
      expect(find.byKey(const ValueKey(2)), findsOneWidget);
    });

    testWidgets('renders GRID when width >= breakpoint', (tester) async {
      await _setSurfaceSize(tester, const Size(1000, 800));
      final items = [1, 2, 3];

      await tester.pumpWidget(_app(ResponsiveEntityList<int>(
        items: items,
        gridBreakpoint: 720,
        thumbnailBuilder: (c, i) => Text('listThumb $i'),
        descriptionBuilder: (c, i) => Text('listDesc $i'),
      )));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(EntityGridItem), findsNWidgets(3));
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('grid uses grid overrides and falls back for others', (tester) async {
      await _setSurfaceSize(tester, const Size(1000, 800));
      final items = [1];

      await tester.pumpWidget(_app(ResponsiveEntityList<int>(
        items: items,
        gridBreakpoint: 720,
        thumbnailBuilder: (c, i) => Text('listThumb $i'),
        descriptionBuilder: (c, i) => Text('listDesc $i'),
        // Only override the grid thumbnail; others fall back to list builders.
        gridThumbnailBuilder: (c, i) => Text('gridThumb $i'),
      )));

      expect(find.text('gridThumb 1'), findsOneWidget);
      expect(find.text('listThumb 1'), findsNothing);
      expect(find.text('listDesc 1'), findsOneWidget);
    });

    testWidgets('custom listSeparatorBuilder is used', (tester) async {
      await _setSurfaceSize(tester, const Size(600, 800));
      final items = [1, 2, 3];

      await tester.pumpWidget(_app(ResponsiveEntityList<int>(
        items: items,
        gridBreakpoint: 720,
        thumbnailBuilder: (c, i) => const SizedBox(),
        descriptionBuilder: (c, i) => Text('row $i'),
        listSeparatorBuilder: (c, i) => SizedBox(key: ValueKey('sep_$i'), height: 2),
      )));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
      expect(find.byKey(const ValueKey('sep_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('sep_1')), findsOneWidget);
    });

    testWidgets('onTap fires for list and grid', (tester) async {
      final items = [1];

      // List
      await _setSurfaceSize(tester, const Size(600, 800));
      var taps = 0;
      await tester.pumpWidget(_app(ResponsiveEntityList<int>(
        items: items,
        gridBreakpoint: 720,
        thumbnailBuilder: (c, i) => const SizedBox(),
        descriptionBuilder: (c, i) => const Text('tapme'),
        onTap: (_) => taps++,
      )));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(taps, 1);

      // Grid
      await _setSurfaceSize(tester, const Size(1000, 800));
      await tester.pumpWidget(_app(ResponsiveEntityList<int>(
        items: items,
        gridBreakpoint: 720,
        thumbnailBuilder: (c, i) => const SizedBox(),
        descriptionBuilder: (c, i) => const Text('tapme-grid'),
        onTap: (_) => taps++,
      )));
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(taps, 2);
    });

    testWidgets('respects custom paddings', (tester) async {
      final items = [1, 2];

      // List padding
      await _setSurfaceSize(tester, const Size(600, 800));
      const listPad = EdgeInsets.only(top: 5, bottom: 7, left: 3, right: 4);
      await tester.pumpWidget(_app(ResponsiveEntityList<int>(
        items: items,
        gridBreakpoint: 720,
        listPadding: listPad,
        thumbnailBuilder: (c, i) => const SizedBox(),
        descriptionBuilder: (c, i) => Text('row $i'),
      )));
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, listPad);

      // Grid padding
      await _setSurfaceSize(tester, const Size(1000, 800));
      const gridPad = EdgeInsets.fromLTRB(1, 2, 3, 4);
      await tester.pumpWidget(_app(ResponsiveEntityList<int>(
        items: items,
        gridBreakpoint: 720,
        gridPadding: gridPad,
        thumbnailBuilder: (c, i) => const SizedBox(),
        descriptionBuilder: (c, i) => Text('row $i'),
      )));
      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.padding, gridPad);
    });
  });
}
