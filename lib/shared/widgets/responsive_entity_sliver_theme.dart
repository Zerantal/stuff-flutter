// lib/shared/widgets/responsive_entity_sliver_theme.dart
import 'package:flutter/material.dart';

/// Density presets for entity tiles.
enum EntityTileDensity { compact, comfy, roomy }

/// Theme extension that centralizes sizing for list + grid tiles.
/// the responsive widgets will auto-pick values from here unless
/// overridden per-call.
@immutable
class ResponsiveEntitySliverTheme extends ThemeExtension<ResponsiveEntitySliverTheme> {
  final double gridHeaderHeight;
  final double gridBodyHeight;
  final double gridTileVerticalPadding;
  final EdgeInsets outerPadding;

  const ResponsiveEntitySliverTheme({
    required this.gridHeaderHeight,
    required this.gridBodyHeight,
    required this.gridTileVerticalPadding,
    required this.outerPadding,
  });

  /// Built-in presets (match the values we’ve been using).
  factory ResponsiveEntitySliverTheme.preset(EntityTileDensity density) {
    switch (density) {
      case EntityTileDensity.compact:
        return const ResponsiveEntitySliverTheme(
          gridHeaderHeight: 120,
          gridBodyHeight: 64,
          gridTileVerticalPadding: 20,
          outerPadding: EdgeInsets.symmetric(horizontal: 4),
        );
      case EntityTileDensity.comfy:
        return const ResponsiveEntitySliverTheme(
          gridHeaderHeight: 140,
          gridBodyHeight: 76,
          gridTileVerticalPadding: 24,
          outerPadding: EdgeInsets.symmetric(horizontal: 8),
        );
      case EntityTileDensity.roomy:
      // ignore: unreachable_switch_default
      default:
        return const ResponsiveEntitySliverTheme(
          gridHeaderHeight: 160,
          gridBodyHeight: 92,
          gridTileVerticalPadding: 28,
          outerPadding: EdgeInsets.symmetric(horizontal: 12),
        );
    }
  }

  @override
  ResponsiveEntitySliverTheme copyWith({
    double? gridHeaderHeight,
    double? gridBodyHeight,
    double? gridTileVerticalPadding,
    EdgeInsets? outerPadding,
  }) {
    return ResponsiveEntitySliverTheme(
      gridHeaderHeight: gridHeaderHeight ?? this.gridHeaderHeight,
      gridBodyHeight: gridBodyHeight ?? this.gridBodyHeight,
      gridTileVerticalPadding: gridTileVerticalPadding ?? this.gridTileVerticalPadding,
      outerPadding: outerPadding ?? this.outerPadding,
    );
  }

  @override
  ResponsiveEntitySliverTheme lerp(ThemeExtension<ResponsiveEntitySliverTheme>? other, double t) {
    if (other is! ResponsiveEntitySliverTheme) return this;
    double lerpD(double a, double b) => a + (b - a) * t;
    return ResponsiveEntitySliverTheme(
      gridHeaderHeight: lerpD(gridHeaderHeight, other.gridHeaderHeight),
      gridBodyHeight: lerpD(gridBodyHeight, other.gridBodyHeight),
      gridTileVerticalPadding: lerpD(gridTileVerticalPadding, other.gridTileVerticalPadding),
      outerPadding: EdgeInsets.lerp(outerPadding, other.outerPadding, t)!,
    );
  }
}
