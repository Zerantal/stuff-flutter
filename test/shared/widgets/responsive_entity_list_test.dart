// test/shared/widgets/responsive_entity_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/responsive_entity_sliver.dart';
import 'package:stuff/shared/widgets/responsive_entity_list.dart';

Widget _wrapWidget(WidgetTester tester, Widget child, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResponsiveEntitySliver & ResponsiveEntityList', () {
    testWidgets('switches to List when width < gridBreakpoint', (tester) async {
      final items = List<int>.generate(4, (i) => i);

      final widget = _wrapWidget(
        tester,
        CustomScrollView(
          slivers: [
            ResponsiveEntitySliver<int>(
              items: items,
              gridBreakpoint: 720.0, // default; just explicit
              headerBuilder: (ctx, i) => Container(key: ValueKey('h-$i')),
              bodyBuilder: (ctx, i) => Text('Item $i', key: ValueKey('b-$i')),
            ),
          ],
        ),
        const Size(600, 800), // narrower than breakpoint
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      // Should be using SliverList, not SliverGrid
      expect(find.byType(SliverList), findsOneWidget);
      expect(find.byType(SliverGrid), findsNothing);
      // All item texts are present
      for (final i in items) {
        expect(find.text('Item $i'), findsOneWidget);
      }
    });

    testWidgets('switches to Grid when width >= gridBreakpoint', (tester) async {
      final items = List<int>.generate(4, (i) => i);

      final widget = _wrapWidget(
        tester,
        CustomScrollView(
          slivers: [
            ResponsiveEntitySliver<int>(
              items: items,
              gridBreakpoint: 720.0,
              headerBuilder: (ctx, i) => Container(key: ValueKey('h-$i')),
              bodyBuilder: (ctx, i) => Text('Item $i', key: ValueKey('b-$i')),
            ),
          ],
        ),
        const Size(1000, 800), // wider than breakpoint
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      // Should be using SliverGrid
      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.byType(SliverList), findsNothing);
      for (final i in items) {
        expect(find.text('Item $i'), findsOneWidget);
      }
    });

    testWidgets('grid: snaps tile width to gridTileWidth (left aligned)', (tester) async {
      // Using defaults: gridPadding: left/right=12; crossSpacing=12; gridTileWidth=240
      // width=1000 => innerBase = 1000 - 24 = 976
      // columns = floor((976+12) / (240+12)) = floor(988/252)=3; desiredInner=744; extra=232
      // SnapAlign.left => left padding ~12; grid tile width should be ~240
      final items = List<int>.generate(5, (i) => i);

      final widget = _wrapWidget(
        tester,
        CustomScrollView(
          slivers: [
            ResponsiveEntitySliver<int>(
              items: items,
              headerBuilder: (ctx, i) => Container(color: Colors.red),
              bodyBuilder: (ctx, i) => const SizedBox.shrink(),
            ),
          ],
        ),
        const Size(1000, 800),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      final firstTile = find.byType(Card).first;
      final size = tester.getSize(firstTile);

      // Expect roughly the configured gridTileWidth (default 240)
      expect(
        (size.width - 240.0).abs() < 1.0,
        isTrue,
        reason: 'Grid cell width should snap to ~240px',
      );
      // Left alignment => first tile left should be very close to left padding (12)
      final left = tester.getTopLeft(firstTile).dx;
      expect(
        (left - 12.0).abs() < 1.0,
        isTrue,
        reason: 'First column should start at left padding ~12px',
      );
    });

    testWidgets('grid: center snap shifts first column right', (tester) async {
      final items = List<int>.generate(3, (i) => i);

      final widget = _wrapWidget(
        tester,
        CustomScrollView(
          slivers: [
            ResponsiveEntitySliver<int>(
              items: items,
              snapAlign: SnapAlign.center,
              headerBuilder: (ctx, i) => Container(color: Colors.blue),
              bodyBuilder: (ctx, i) => const SizedBox.shrink(),
            ),
          ],
        ),
        const Size(1000, 800),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      final firstTile = find.byType(Card).first;
      final left = tester.getTopLeft(firstTile).dx;
      expect(
        left,
        greaterThan(12.0),
        reason: 'Center snap should add extra padding on the left beyond the base 12px',
      );
    });

    testWidgets('grid: trailing height defaults when trailingBuilder is present', (tester) async {
      final items = [1, 2, 3];

      // Configure explicit heights (so we can assert exact tile height):
      // header=100, body=60, gap=10, vpad=20. With trailing present but height unspecified,
      // effective trailing height = 40 (default).
      // tileHeight = 20 + 100 + (10 + 10) + 40 + 60 = 240
      final widget = _wrapWidget(
        tester,
        CustomScrollView(
          slivers: [
            ResponsiveEntitySliver<int>(
              items: items,
              gridHeaderHeight: 100,
              gridBodyTargetHeight: 60,
              gridSectionGap: 10,
              gridTileVerticalPadding: 20,
              // Not providing gridTrailingHeight -> triggers default 40 when trailingBuilder != null
              trailingBuilder: (ctx, i) => const SizedBox(width: 16, height: 1),
              headerBuilder: (ctx, i) => Container(color: Colors.green),
              bodyBuilder: (ctx, i) => const SizedBox.shrink(),
            ),
          ],
        ),
        const Size(1000, 800),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      final h = tester.getSize(find.byType(Card).first).height;
      expect(
        (h - 240.0).abs() < 1.0,
        isTrue,
        reason: 'Tile height should include default trailing area (≈240px)',
      );
    });

    testWidgets('grid: smaller tile height without trailingBuilder', (tester) async {
      final items = [1, 2, 3];

      // Same explicit config as above but with NO trailingBuilder.
      // tileHeight = 20 + 100 + (10) + 0 + 60 = 190
      final widget = _wrapWidget(
        tester,
        CustomScrollView(
          slivers: [
            ResponsiveEntitySliver<int>(
              items: items,
              gridHeaderHeight: 100,
              gridBodyTargetHeight: 60,
              gridSectionGap: 10,
              gridTileVerticalPadding: 20,
              headerBuilder: (ctx, i) => Container(color: Colors.green),
              bodyBuilder: (ctx, i) => const SizedBox.shrink(),
            ),
          ],
        ),
        const Size(1000, 800),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      final h = tester.getSize(find.byType(Card).first).height;
      expect(
        (h - 190.0).abs() < 1.0,
        isTrue,
        reason: 'Tile height should be smaller when no trailing area is reserved',
      );
    });

    testWidgets('list: uses separator builder and handles taps', (tester) async {
      final items = List<int>.generate(4, (i) => i);
      int taps = 0;

      final widget = _wrapWidget(
        tester,
        CustomScrollView(
          slivers: [
            ResponsiveEntitySliver<int>(
              items: items,
              gridBreakpoint: 720.0,
              listSeparatorBuilder: (ctx, _) =>
                  const Divider(key: ValueKey('sep'), height: 1, thickness: 0.6),
              headerBuilder: (ctx, i) => SizedBox(key: ValueKey('h-$i'), width: 72, height: 72),
              bodyBuilder: (ctx, i) => Text('Row $i', key: ValueKey('r-$i')),
              onTap: (_) => taps++,
            ),
          ],
        ),
        const Size(600, 800), // forces list mode
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      // Should show (items.length - 1) separators
      expect(find.byKey(const ValueKey('sep')), findsNWidgets(items.length - 1));

      // Tap a row (InkWell is in the list tile)
      await tester.tap(find.text('Row 1'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('ResponsiveEntityList passes sliversBefore/After through', (tester) async {
      final items = [1, 2];

      final widget = _wrapWidget(
        tester,
        ResponsiveEntityList<int>(
          items: items,
          headerBuilder: (ctx, i) => Container(key: ValueKey('top-$i')),
          bodyBuilder: (ctx, i) => Text('Body $i', key: ValueKey('body-$i')),
          sliversBefore: const [
            SliverToBoxAdapter(
              child: SizedBox(height: 10, child: Text('before', key: ValueKey('before'))),
            ),
          ],
          sliversAfter: const [
            SliverToBoxAdapter(
              child: SizedBox(height: 10, child: Text('after', key: ValueKey('after'))),
            ),
          ],
        ),
        const Size(1000, 800),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('before')), findsOneWidget);
      expect(find.byKey(const ValueKey('after')), findsOneWidget);
      // Items render too
      expect(find.byKey(const ValueKey('body-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('body-2')), findsOneWidget);
    });

    testWidgets('ResponsiveEntityList mirrors Sliver configuration (grid mode)', (tester) async {
      final items = List<int>.generate(3, (i) => i);

      final widget = _wrapWidget(
        tester,
        ResponsiveEntityList<int>(
          items: items,
          // force grid
          gridBreakpoint: 480.0,
          gridTileWidth: 200.0,
          gridPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          gridCrossAxisSpacing: 8.0,
          gridMainAxisSpacing: 8.0,
          headerBuilder: (ctx, i) => Container(color: Colors.orange),
          bodyBuilder: (ctx, i) => const SizedBox.shrink(),
        ),
        const Size(1000, 800),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();
      expect(find.byType(SliverGrid), findsOneWidget);

      final tile = find.byType(Card).first;
      final width = tester.getSize(tile).width;
      // gridTileWidth is 200, so snapped width should be ~200
      expect((width - 200.0).abs() < 1.0, isTrue);
    });
  });
}
