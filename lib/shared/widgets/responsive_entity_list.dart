import 'package:flutter/material.dart';
import 'responsive_entity_sliver.dart';
import 'entity_tile_theme.dart';

/// A convenience wrapper that hosts [ResponsiveEntitySliver] inside a
/// [CustomScrollView].
class ResponsiveEntityList<T> extends StatelessWidget {
  const ResponsiveEntityList({
    super.key,
    required this.items,
    required this.headerBuilder,
    required this.bodyBuilder,
    this.trailingBuilder,
    this.onTap,

    // ScrollView plumbing
    this.controller,
    this.primary,
    this.physics,
    this.cacheExtent,
    this.sliversBefore = const <Widget>[],
    this.sliversAfter = const <Widget>[],

    // Sliver config (mirrors ResponsiveEntitySliver)
    this.gridBreakpoint = 720.0,
    this.snapToTileWidth = true,
    this.snapAlign = SnapAlign.left,
    this.gridTileWidth = 240.0,
    this.gridMinColumns = 2,
    this.gridMaxColumns = 8,

    this.density = EntityTileDensity.comfy,

    this.gridHeaderHeight,
    this.gridBodyTargetHeight,
    this.gridTrailingHeight,
    this.forceGridTrailingSpace = false,
    this.gridSectionGap,
    this.gridTileVerticalPadding,

    this.gridPadding = const EdgeInsets.fromLTRB(12, 12, 12, 96),
    this.gridMainAxisSpacing = 12.0,
    this.gridCrossAxisSpacing = 12.0,

    this.listHeaderWidth,
    this.listHeaderHeight,
    this.listTileMinHeight,
    this.listPadding = const EdgeInsets.only(top: 8, bottom: 88),
    this.listSeparatorBuilder,
  });

  // Data
  final List<T> items;

  // Slots
  final Widget Function(BuildContext, T) headerBuilder;
  final Widget Function(BuildContext, T) bodyBuilder;
  final Widget Function(BuildContext, T)? trailingBuilder;
  final void Function(T item)? onTap;

  // ScrollView controls
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final double? cacheExtent;
  final List<Widget> sliversBefore;
  final List<Widget> sliversAfter;

  // Sliver config
  final double gridBreakpoint;
  final bool snapToTileWidth;
  final SnapAlign snapAlign;
  final double gridTileWidth;
  final int gridMinColumns;
  final int gridMaxColumns;

  // Density & theme
  final EntityTileDensity density;

  // Grid (nullable => from theme)
  final double? gridHeaderHeight;
  final double? gridBodyTargetHeight;
  final double? gridTrailingHeight;
  final bool forceGridTrailingSpace;
  final double? gridSectionGap;
  final double? gridTileVerticalPadding;

  final EdgeInsets gridPadding;
  final double gridMainAxisSpacing;
  final double gridCrossAxisSpacing;

  // List (nullable => from theme)
  final double? listHeaderWidth;
  final double? listHeaderHeight;
  final double? listTileMinHeight;
  final EdgeInsets listPadding;
  final Widget Function(BuildContext, int)? listSeparatorBuilder;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      primary: primary,
      physics: physics,
      cacheExtent: cacheExtent,
      slivers: <Widget>[
        ...sliversBefore,
        ResponsiveEntitySliver<T>(
          items: items,
          headerBuilder: headerBuilder,
          bodyBuilder: bodyBuilder,
          trailingBuilder: trailingBuilder,
          onTap: onTap,
          gridBreakpoint: gridBreakpoint,
          snapToTileWidth: snapToTileWidth,
          snapAlign: snapAlign,
          gridTileWidth: gridTileWidth,
          gridMinColumns: gridMinColumns,
          gridMaxColumns: gridMaxColumns,

          density: density,

          gridHeaderHeight: gridHeaderHeight,
          gridBodyTargetHeight: gridBodyTargetHeight,
          gridTrailingHeight: gridTrailingHeight,
          forceGridTrailingSpace: forceGridTrailingSpace,
          gridSectionGap: gridSectionGap,
          gridTileVerticalPadding: gridTileVerticalPadding,

          gridPadding: gridPadding,
          gridMainAxisSpacing: gridMainAxisSpacing,
          gridCrossAxisSpacing: gridCrossAxisSpacing,

          listHeaderWidth: listHeaderWidth,
          listHeaderHeight: listHeaderHeight,
          listTileMinHeight: listTileMinHeight,
          listPadding: listPadding,
          listSeparatorBuilder: listSeparatorBuilder,
        ),
        ...sliversAfter,
      ],
    );
  }
}
