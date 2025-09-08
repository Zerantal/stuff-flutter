// test/shared/widgets/entity_tile_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/entity_tile_theme.dart';

void main() {
  group('EntityTileTheme.preset', () {
    test('compact preset has expected values', () {
      final theme = EntityTileTheme.preset(EntityTileDensity.compact);

      expect(theme.gridHeaderHeight, 120);
      expect(theme.gridBodyTargetHeight, 64);
      expect(theme.listHeaderWidth, 64);
      expect(theme.listTileMinHeight, 80);
    });

    test('comfy preset has expected values', () {
      final theme = EntityTileTheme.preset(EntityTileDensity.comfy);

      expect(theme.gridHeaderHeight, 140);
      expect(theme.gridBodyTargetHeight, 76);
      expect(theme.listHeaderWidth, 72);
      expect(theme.listTileMinHeight, 88);
    });

    test('roomy preset has expected values', () {
      final theme = EntityTileTheme.preset(EntityTileDensity.roomy);

      expect(theme.gridHeaderHeight, 160);
      expect(theme.gridBodyTargetHeight, 92);
      expect(theme.listHeaderWidth, 80);
      expect(theme.listTileMinHeight, 96);
    });
  });

  group('copyWith', () {
    test('overrides only specified fields', () {
      final base = EntityTileTheme.preset(EntityTileDensity.comfy);
      final modified = base.copyWith(gridHeaderHeight: 200);

      expect(modified.gridHeaderHeight, 200);
      // unchanged fields remain the same
      expect(modified.gridBodyTargetHeight, base.gridBodyTargetHeight);
      expect(modified.listHeaderWidth, base.listHeaderWidth);
    });

    test('returns new instance even if no changes', () {
      final base = EntityTileTheme.preset(EntityTileDensity.comfy);
      final copy = base.copyWith();

      expect(copy, isNot(same(base)));
      expect(copy.gridHeaderHeight, base.gridHeaderHeight);
    });
  });

  group('lerp', () {
    test('returns self if other is not EntityTileTheme', () {
      final base = EntityTileTheme.preset(EntityTileDensity.compact);
      final result = base.lerp(null, 0.5);

      expect(result, same(base));
    });

    test('interpolates numeric values between two themes', () {
      final a = const EntityTileTheme(
        gridHeaderHeight: 100,
        gridBodyTargetHeight: 50,
        gridTrailingHeight: 10,
        gridSectionGap: 8,
        gridTileVerticalPadding: 20,
        listHeaderWidth: 60,
        listHeaderHeight: 60,
        listTileMinHeight: 70,
      );
      final b = const EntityTileTheme(
        gridHeaderHeight: 200,
        gridBodyTargetHeight: 150,
        gridTrailingHeight: 30,
        gridSectionGap: 12,
        gridTileVerticalPadding: 40,
        listHeaderWidth: 80,
        listHeaderHeight: 80,
        listTileMinHeight: 90,
      );

      final mid = a.lerp(b, 0.5);

      expect(mid.gridHeaderHeight, closeTo(150, 0.001));
      expect(mid.gridBodyTargetHeight, closeTo(100, 0.001));
      expect(mid.listHeaderWidth, closeTo(70, 0.001));
      expect(mid.listTileMinHeight, closeTo(80, 0.001));
    });
  });

  group('integration with ThemeData', () {
    testWidgets('EntityTileTheme can be added to ThemeData and retrieved', (tester) async {
      final theme = EntityTileTheme.preset(EntityTileDensity.roomy);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[theme]),
          home: Builder(
            builder: (context) {
              final ext = Theme.of(context).extension<EntityTileTheme>();
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
      final compact = EntityTileTheme.preset(EntityTileDensity.compact);
      final roomy = EntityTileTheme.preset(EntityTileDensity.roomy);

      final theme1 = ThemeData(extensions: [compact]);
      final theme2 = ThemeData(extensions: [roomy]);

      // Interpolate halfway
      final midTheme = ThemeData.lerp(theme1, theme2, 0.5);
      final ext = midTheme.extension<EntityTileTheme>();

      expect(ext, isNotNull);
      // Should be halfway between 120 and 160
      expect(ext!.gridHeaderHeight, closeTo(140, 0.001));
    });
  });
}
