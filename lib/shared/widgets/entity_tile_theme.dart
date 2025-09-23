// lib/shared/widgets/entity_tile_theme.dart
import 'package:flutter/material.dart';

/// Density presets for entity tiles.
enum EntityTileDensity { compact, comfy, roomy }

/// Theme extension that centralizes sizing for list + grid tiles.
/// If you add this to your app's ThemeData, the responsive widgets
/// will auto-pick values from here unless you override them per-call.
@immutable
class EntityTileTheme extends ThemeExtension<EntityTileTheme> {
  final double gridHeaderHeight;
  final double gridBodyHeight; // body min height budget; Expanded fills the rest
  final double gridTileVerticalPadding;

  const EntityTileTheme({
    required this.gridHeaderHeight,
    required this.gridBodyHeight,
    required this.gridTileVerticalPadding,
  });

  /// Built-in presets (match the values we’ve been using).
  factory EntityTileTheme.preset(EntityTileDensity density) {
    switch (density) {
      case EntityTileDensity.compact:
        return const EntityTileTheme(
          gridHeaderHeight: 120,
          gridBodyHeight: 64,
          gridTileVerticalPadding: 20,
        );
      case EntityTileDensity.roomy:
        return const EntityTileTheme(
          gridHeaderHeight: 160,
          gridBodyHeight: 92,
          gridTileVerticalPadding: 28,
        );
      case EntityTileDensity.comfy:
      // ignore: unreachable_switch_default
      default:
        return const EntityTileTheme(
          gridHeaderHeight: 140,
          gridBodyHeight: 76,
          gridTileVerticalPadding: 24,
        );
    }
  }

  @override
  EntityTileTheme copyWith({
    double? gridHeaderHeight,
    double? gridBodyHeight,
    double? gridTileVerticalPadding,
  }) {
    return EntityTileTheme(
      gridHeaderHeight: gridHeaderHeight ?? this.gridHeaderHeight,
      gridBodyHeight: gridBodyHeight ?? this.gridBodyHeight,
      gridTileVerticalPadding: gridTileVerticalPadding ?? this.gridTileVerticalPadding,
    );
  }

  @override
  EntityTileTheme lerp(ThemeExtension<EntityTileTheme>? other, double t) {
    if (other is! EntityTileTheme) return this;
    double lerpD(double a, double b) => a + (b - a) * t;
    return EntityTileTheme(
      gridHeaderHeight: lerpD(gridHeaderHeight, other.gridHeaderHeight),
      gridBodyHeight: lerpD(gridBodyHeight, other.gridBodyHeight),
      gridTileVerticalPadding: lerpD(gridTileVerticalPadding, other.gridTileVerticalPadding),
    );
  }
}
