// test/shared/widgets/entity_tile_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/responsive_entity_sliver_theme.dart';

void main() {
  group('EntityTileTheme.preset', () {
    test('compact preset has expected values', () {
      final theme = ResponsiveEntitySliverTheme.preset(EntityTileDensity.compact);

      expect(theme.gridHeaderHeight, 120);
      expect(theme.gridBodyHeight, 64);
    });

    test('comfy preset has expected values', () {
      final theme = ResponsiveEntitySliverTheme.preset(EntityTileDensity.comfy);

      expect(theme.gridHeaderHeight, 140);
      expect(theme.gridBodyHeight, 76);
    });

    test('roomy preset has expected values', () {
      final theme = ResponsiveEntitySliverTheme.preset(EntityTileDensity.roomy);

      expect(theme.gridHeaderHeight, 160);
      expect(theme.gridBodyHeight, 92);
    });
  });

  group('copyWith', () {
    test('overrides only specified fields', () {
      final base = ResponsiveEntitySliverTheme.preset(EntityTileDensity.comfy);
      final modified = base.copyWith(gridHeaderHeight: 200);

      expect(modified.gridHeaderHeight, 200);
      // unchanged fields remain the same
      expect(modified.gridBodyHeight, base.gridBodyHeight);
    });

    test('returns new instance even if no changes', () {
      final base = ResponsiveEntitySliverTheme.preset(EntityTileDensity.comfy);
      final copy = base.copyWith();

      expect(copy, isNot(same(base)));
      expect(copy.gridHeaderHeight, base.gridHeaderHeight);
    });
  });

  group('lerp', () {
    test('returns self if other is not EntityTileTheme', () {
      final base = ResponsiveEntitySliverTheme.preset(EntityTileDensity.compact);
      final result = base.lerp(null, 0.5);

      expect(result, same(base));
    });

    test('interpolates numeric values between two themes', () {
      final a = const ResponsiveEntitySliverTheme(
        gridHeaderHeight: 100,
        gridBodyHeight: 50,
        gridTileVerticalPadding: 20,
        outerPadding: EdgeInsets.symmetric(horizontal: 4),
      );
      final b = const ResponsiveEntitySliverTheme(
        gridHeaderHeight: 200,
        gridBodyHeight: 150,
        gridTileVerticalPadding: 40,
        outerPadding: EdgeInsets.symmetric(horizontal: 8),
      );

      final mid = a.lerp(b, 0.5);

      expect(mid.gridHeaderHeight, closeTo(150, 0.001));
      expect(mid.gridBodyHeight, closeTo(100, 0.001));
    });
  });

  group('integration with ThemeData', () {
    testWidgets('EntityTileTheme can be added to ThemeData and retrieved', (tester) async {
      final theme = ResponsiveEntitySliverTheme.preset(EntityTileDensity.roomy);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[theme]),
          home: Builder(
            builder: (context) {
              final ext = Theme.of(context).extension<ResponsiveEntitySliverTheme>();
              return Text(
                'gridHeaderHeight=${ext?.gridHeaderHeight}',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('gridHeaderHeight=160.0'), findsOneWidget);
    });

    testWidgets('copyWith and lerp integrate into ThemeData.lerp', (tester) async {
      final compact = ResponsiveEntitySliverTheme.preset(EntityTileDensity.compact);
      final roomy = ResponsiveEntitySliverTheme.preset(EntityTileDensity.roomy);

      final theme1 = ThemeData(extensions: [compact]);
      final theme2 = ThemeData(extensions: [roomy]);

      // Interpolate halfway
      final midTheme = ThemeData.lerp(theme1, theme2, 0.5);
      final ext = midTheme.extension<ResponsiveEntitySliverTheme>();

      expect(ext, isNotNull);
      // Should be halfway between 120 and 160
      expect(ext!.gridHeaderHeight, closeTo(140, 0.001));
    });
  });
}
