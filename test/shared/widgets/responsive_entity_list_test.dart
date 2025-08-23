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

      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            thumbnailBuilder: (c, i) => Text('thumb $i'),
            descriptionBuilder: (c, i) => Text('desc $i'),
          ),
        ),
      );

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

      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            thumbnailBuilder: (c, i) => Text('listThumb $i'),
            descriptionBuilder: (c, i) => Text('listDesc $i'),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(EntityGridItem), findsNWidgets(3));
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('grid uses grid overrides and falls back for others', (tester) async {
      await _setSurfaceSize(tester, const Size(1000, 800));
      final items = [1];

      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            thumbnailBuilder: (c, i) => Text('listThumb $i'),
            descriptionBuilder: (c, i) => Text('listDesc $i'),
            // Only override the grid thumbnail; others fall back to list builders.
            gridThumbnailBuilder: (c, i) => Text('gridThumb $i'),
          ),
        ),
      );

      expect(find.text('gridThumb 1'), findsOneWidget);
      expect(find.text('listThumb 1'), findsNothing);
      expect(find.text('listDesc 1'), findsOneWidget);
    });

    testWidgets('custom listSeparatorBuilder is used', (tester) async {
      await _setSurfaceSize(tester, const Size(600, 800));
      final items = [1, 2, 3];

      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            thumbnailBuilder: (c, i) => const SizedBox(),
            descriptionBuilder: (c, i) => Text('row $i'),
            listSeparatorBuilder: (c, i) => SizedBox(key: ValueKey('sep_$i'), height: 2),
          ),
        ),
      );

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
      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            thumbnailBuilder: (c, i) => const SizedBox(),
            descriptionBuilder: (c, i) => const Text('tapme'),
            onTap: (_) => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(taps, 1);

      // Grid
      await _setSurfaceSize(tester, const Size(1000, 800));
      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            thumbnailBuilder: (c, i) => const SizedBox(),
            descriptionBuilder: (c, i) => const Text('tapme-grid'),
            onTap: (_) => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(taps, 2);
    });

    testWidgets('respects custom paddings', (tester) async {
      final items = [1, 2];

      // List padding
      await _setSurfaceSize(tester, const Size(600, 800));
      const listPad = EdgeInsets.only(top: 5, bottom: 7, left: 3, right: 4);
      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            listPadding: listPad,
            thumbnailBuilder: (c, i) => const SizedBox(),
            descriptionBuilder: (c, i) => Text('row $i'),
          ),
        ),
      );
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, listPad);

      // Grid padding
      await _setSurfaceSize(tester, const Size(1000, 800));
      const gridPad = EdgeInsets.fromLTRB(1, 2, 3, 4);
      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            gridPadding: gridPad,
            thumbnailBuilder: (c, i) => const SizedBox(),
            descriptionBuilder: (c, i) => Text('row $i'),
          ),
        ),
      );
      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.padding, gridPad);
    });
  });

  group('grid layout', () {
    // Helper to build a grid with predictable conditions.
    Future<void> pumpGrid({
      required WidgetTester tester,
      required Size surfaceSize,
      required List<int> items,
      double aspectRatio = 1.25,
      double minTileWidth = 300,
      double maxTileWidth = 340,
    }) async {
      await _setSurfaceSize(tester, surfaceSize);
      await tester.pumpWidget(
        _app(
          ResponsiveEntityList<int>(
            items: items,
            gridBreakpoint: 720,
            gridPadding: EdgeInsets.zero, // simplify width math in tests
            aspectRatio: aspectRatio,
            minTileWidth: minTileWidth,
            maxTileWidth: maxTileWidth,
            // simple children so they lay out quickly
            thumbnailBuilder: (c, i) => const SizedBox(),
            descriptionBuilder: (c, i) => Text('item $i'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('picks 3 columns at 1000px with min=300, max=340', (tester) async {
      // With width=1000, padding=0, spacing=12:
      // c=3 -> w = (1000 - 12*(3-1)) / 3 = (1000 - 24)/3 ≈ 325.3 ∈ [300,340]  ✅
      // c=2 -> w ≈ 494 > 340 ❌
      // c=4 -> w ≈ 241 < 300 ❌
      await pumpGrid(
        tester: tester,
        surfaceSize: const Size(1000, 800),
        items: List.generate(8, (i) => i + 1),
        minTileWidth: 300,
        maxTileWidth: 340,
        aspectRatio: 1.25,
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
      expect(delegate.childAspectRatio, 1.25);

      // Verify a tile’s measured size respects aspect & bounds.
      final firstTile = find.byType(EntityGridItem).first;
      final size = tester.getSize(firstTile);
      expect(size.width, inInclusiveRange(300, 340));
      // Width / height ~= aspect ratio
      expect((size.width / size.height), closeTo(1.25, 0.05));
    });

    testWidgets('picks 4 columns at 1400px with min=300, max=360', (tester) async {
      // With width=1400, padding=0, spacing=12:
      // c=4 -> w = (1400 - 36) / 4 = 341 ∈ [300,360] ✅
      // c=3 -> w ≈ 458 > 360 ❌
      // c=5 -> w ≈ 270 < 300 ❌
      await pumpGrid(
        tester: tester,
        surfaceSize: const Size(1400, 900),
        items: List.generate(10, (i) => i + 1),
        minTileWidth: 300,
        maxTileWidth: 360,
        aspectRatio: 1.25,
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
      expect(delegate.childAspectRatio, 1.25);

      final firstTile = find.byType(EntityGridItem).first;
      final size = tester.getSize(firstTile);
      expect(size.width, inInclusiveRange(300, 360));
      expect((size.width / size.height), closeTo(1.25, 0.05));
    });

    testWidgets('enforces larger tiles (2 cols) at 1600px with min=700, max=820', (tester) async {
      // With width=1600, padding=0, spacing=12:
      // c=2 -> w = (1600 - 12) / 2 = 794 ∈ [700,820] ✅
      // c=3 -> w ≈ 525 < 700 ❌
      await pumpGrid(
        tester: tester,
        surfaceSize: const Size(1600, 900),
        items: List.generate(6, (i) => i + 1),
        minTileWidth: 700,
        maxTileWidth: 820,
        aspectRatio: 1.25,
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      final firstTile = find.byType(EntityGridItem).first;
      final size = tester.getSize(firstTile);
      expect(size.width, inInclusiveRange(700, 820));
      expect((size.width / size.height), closeTo(1.25, 0.05));
    });
  });
}
