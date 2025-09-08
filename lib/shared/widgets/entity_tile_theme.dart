import 'package:flutter/material.dart';

/// Density presets for entity tiles.
enum EntityTileDensity { compact, comfy, roomy }

/// Theme extension that centralizes sizing for list + grid tiles.
/// If you add this to your app's ThemeData, the responsive widgets
/// will auto-pick values from here unless you override them per-call.
@immutable
class EntityTileTheme extends ThemeExtension<EntityTileTheme> {
  final double gridHeaderHeight;
  final double gridBodyTargetHeight; // body min height budget; Expanded fills the rest
  final double gridTrailingHeight;
  final double gridSectionGap;
  final double gridTileVerticalPadding;

  final double listHeaderWidth;
  final double listHeaderHeight;
  final double listTileMinHeight;

  const EntityTileTheme({
    required this.gridHeaderHeight,
    required this.gridBodyTargetHeight,
    required this.gridTrailingHeight,
    required this.gridSectionGap,
    required this.gridTileVerticalPadding,
    required this.listHeaderWidth,
    required this.listHeaderHeight,
    required this.listTileMinHeight,
  });

  /// Built-in presets (match the values we’ve been using).
  factory EntityTileTheme.preset(EntityTileDensity density) {
    switch (density) {
      case EntityTileDensity.compact:
        return const EntityTileTheme(
          gridHeaderHeight: 120,
          gridBodyTargetHeight: 64,
          gridTrailingHeight: 0,
          gridSectionGap: 8,
          gridTileVerticalPadding: 20,
          listHeaderWidth: 64,
          listHeaderHeight: 64,
          listTileMinHeight: 80,
        );
      case EntityTileDensity.roomy:
        return const EntityTileTheme(
          gridHeaderHeight: 160,
          gridBodyTargetHeight: 92,
          gridTrailingHeight: 0,
          gridSectionGap: 10,
          gridTileVerticalPadding: 28,
          listHeaderWidth: 80,
          listHeaderHeight: 80,
          listTileMinHeight: 96,
        );
      case EntityTileDensity.comfy:
      // ignore: unreachable_switch_default
      default:
        return const EntityTileTheme(
          gridHeaderHeight: 140,
          gridBodyTargetHeight: 76,
          gridTrailingHeight: 0,
          gridSectionGap: 8,
          gridTileVerticalPadding: 24,
          listHeaderWidth: 72,
          listHeaderHeight: 72,
          listTileMinHeight: 88,
        );
    }
  }

  @override
  EntityTileTheme copyWith({
    double? gridHeaderHeight,
    double? gridBodyTargetHeight,
    double? gridTrailingHeight,
    double? gridSectionGap,
    double? gridTileVerticalPadding,
    double? listHeaderWidth,
    double? listHeaderHeight,
    double? listTileMinHeight,
  }) {
    return EntityTileTheme(
      gridHeaderHeight: gridHeaderHeight ?? this.gridHeaderHeight,
      gridBodyTargetHeight: gridBodyTargetHeight ?? this.gridBodyTargetHeight,
      gridTrailingHeight: gridTrailingHeight ?? this.gridTrailingHeight,
      gridSectionGap: gridSectionGap ?? this.gridSectionGap,
      gridTileVerticalPadding: gridTileVerticalPadding ?? this.gridTileVerticalPadding,
      listHeaderWidth: listHeaderWidth ?? this.listHeaderWidth,
      listHeaderHeight: listHeaderHeight ?? this.listHeaderHeight,
      listTileMinHeight: listTileMinHeight ?? this.listTileMinHeight,
    );
  }

  @override
  EntityTileTheme lerp(ThemeExtension<EntityTileTheme>? other, double t) {
    if (other is! EntityTileTheme) return this;
    double lerpD(double a, double b) => a + (b - a) * t;
    return EntityTileTheme(
      gridHeaderHeight: lerpD(gridHeaderHeight, other.gridHeaderHeight),
      gridBodyTargetHeight: lerpD(gridBodyTargetHeight, other.gridBodyTargetHeight),
      gridTrailingHeight: lerpD(gridTrailingHeight, other.gridTrailingHeight),
      gridSectionGap: lerpD(gridSectionGap, other.gridSectionGap),
      gridTileVerticalPadding: lerpD(gridTileVerticalPadding, other.gridTileVerticalPadding),
      listHeaderWidth: lerpD(listHeaderWidth, other.listHeaderWidth),
      listHeaderHeight: lerpD(listHeaderHeight, other.listHeaderHeight),
      listTileMinHeight: lerpD(listTileMinHeight, other.listTileMinHeight),
    );
  }
}
