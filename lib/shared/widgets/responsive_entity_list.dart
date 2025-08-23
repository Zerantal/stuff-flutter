// lib/shared/widgets/responsive_entity_list.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'entity_item.dart';

class ResponsiveEntityList<T> extends StatelessWidget {
  const ResponsiveEntityList({
    super.key,
    required this.items,
    required this.thumbnailBuilder,
    required this.descriptionBuilder,
    this.trailingBuilder,
    this.onTap,

    // Grid-specific overrides (optional)
    this.gridThumbnailBuilder,
    this.gridDescriptionBuilder,
    this.gridTrailingBuilder,

    // Layout tuning
    this.gridBreakpoint = 720,
    this.listPadding = const EdgeInsets.only(bottom: 88, top: 8),
    this.gridPadding = const EdgeInsets.fromLTRB(12, 12, 12, 96),
    this.gridMainAxisSpacing = 12,
    this.gridCrossAxisSpacing = 12,
    this.listSeparatorBuilder,

    // Tile sizing (hard constraints)
    this.aspectRatio = 1.25,
    this.minTileWidth = 160,
    this.maxTileWidth = 500,
  }) : assert(aspectRatio > 0),
       assert(minTileWidth > 0),
       assert(maxTileWidth >= minTileWidth),
       // Heights are derived from width constraints and aspect ratio
       minTileHeight = minTileWidth / aspectRatio,
       maxTileHeight = maxTileWidth / aspectRatio;

  final List<T> items;

  // List builders
  final Widget Function(BuildContext context, T item) thumbnailBuilder;
  final Widget Function(BuildContext context, T item) descriptionBuilder;
  final Widget Function(BuildContext context, T item)? trailingBuilder;
  final void Function(T item)? onTap;

  // Grid builders (fallback to list builders if not provided)
  final Widget Function(BuildContext context, T item)? gridThumbnailBuilder;
  final Widget Function(BuildContext context, T item)? gridDescriptionBuilder;
  final Widget Function(BuildContext context, T item)? gridTrailingBuilder;

  // Layout options
  final double gridBreakpoint;
  final EdgeInsets listPadding;
  final EdgeInsets gridPadding;
  final double gridMainAxisSpacing;
  final double gridCrossAxisSpacing;
  final Widget Function(BuildContext, int)? listSeparatorBuilder;

  // Tile sizing (hard constraints)
  final double aspectRatio; // w/h
  final double minTileWidth;
  final double maxTileWidth;
  final double minTileHeight; // = minTileWidth / aspectRatio
  final double maxTileHeight; // = maxTileWidth / aspectRatio

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isGrid = screen.width >= gridBreakpoint;
        if (!isGrid) {
          return ListView.separated(
            padding: listPadding,
            itemCount: items.length,
            separatorBuilder: listSeparatorBuilder ?? (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              return EntityListItem(
                key: ValueKey(item),
                thumbnail: thumbnailBuilder(context, item),
                description: descriptionBuilder(context, item),
                trailing: trailingBuilder?.call(context, item),
                onTap: onTap == null ? null : () => onTap!(item),
              );
            },
          );
        }

        final cfg = _computeGridConfig(
          constraints: constraints,
          screenSize: screen,
          itemCount: items.length,
        );

        final thumbB = gridThumbnailBuilder ?? thumbnailBuilder;
        final descB = gridDescriptionBuilder ?? descriptionBuilder;
        final trailB = gridTrailingBuilder ?? trailingBuilder;

        return GridView.builder(
          padding: gridPadding,
          physics: cfg.physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cfg.columns,
            crossAxisSpacing: gridCrossAxisSpacing,
            mainAxisSpacing: gridMainAxisSpacing,
            childAspectRatio: aspectRatio, // w/h
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return EntityGridItem(
              thumbnail: thumbB(context, item),
              description: descB(context, item),
              trailing: trailB?.call(context, item),
              onTap: onTap == null ? null : () => onTap!(item),
            );
          },
        );
      },
    );
  }

  /// Decides the best grid layout given constraints and the heuristic:
  /// 1) maximize number of visible tiles that fit (no horizontal scroll; and
  ///    no vertical scroll when possible),
  /// 2) break ties by maximizing used area of visible tiles.
  _GridConfig _computeGridConfig({
    required BoxConstraints constraints,
    required Size screenSize,
    required int itemCount,
  }) {
    final viewportW = constraints.maxWidth;
    final viewportH = constraints.hasBoundedHeight ? constraints.maxHeight : screenSize.height;

    // Inner content area after padding.
    final innerW = math.max(0.0, viewportW - gridPadding.left - gridPadding.right);
    final innerH = math.max(0.0, viewportH - gridPadding.top - gridPadding.bottom);

    // Candidate column range so that min/max width constraints are respected.
    final sX = gridCrossAxisSpacing;
    int cMin = ((innerW + sX) / (maxTileWidth + sX)).ceil();
    int cMax = ((innerW + sX) / (minTileWidth + sX)).floor();

    if (!cMin.isFinite || cMin < 1) cMin = 1;
    if (!cMax.isFinite || cMax < 1) cMax = 1;
    if (cMin > cMax) {
      // Extreme constraints: fallback to a sane single candidate.
      cMin = cMax = 1;
    }

    final best = _pickBestColumns(
      cMin: cMin,
      cMax: cMax,
      innerW: innerW,
      innerH: innerH,
      itemCount: itemCount,
      sX: sX,
      sY: gridMainAxisSpacing,
    );

    // If all items fit without vertical scrolling, disable scroll.
    final wBest = (innerW - (best.columns - 1) * sX) / best.columns;
    final hBest = wBest / aspectRatio;
    final rowsFit = ((innerH + gridMainAxisSpacing) / (hBest + gridMainAxisSpacing)).floor();
    final fitsAll = (rowsFit * best.columns) >= itemCount;
    final physics = fitsAll ? const NeverScrollableScrollPhysics() : null;

    return _GridConfig(columns: best.columns, physics: physics);
  }

  _BestPick _pickBestColumns({
    required int cMin,
    required int cMax,
    required double innerW,
    required double innerH,
    required int itemCount,
    required double sX,
    required double sY,
  }) {
    int bestC = cMin;
    int bestVisible = -1;
    double bestUsedArea = -1.0;

    for (int c = cMin; c <= cMax; c++) {
      final w = (innerW - (c - 1) * sX) / c;
      if (w.isNaN || w <= 0) continue;

      // Enforce width bounds (heights follow from aspect ratio).
      if (w < minTileWidth - 0.5 || w > maxTileWidth + 0.5) continue;

      final h = w / aspectRatio;

      // Rows that fit vertically with spacing considered.
      final rowsFit = ((innerH + sY) / (h + sY)).floor();
      final visible = math.min(itemCount, math.max(0, rowsFit) * c);
      final usedArea = visible * w * h;

      if (visible > bestVisible || (visible == bestVisible && usedArea > bestUsedArea)) {
        bestVisible = visible;
        bestUsedArea = usedArea;
        bestC = c;
      }
    }

    // If nothing feasible found (very small width), fall back to 1 col.
    if (bestVisible < 0) {
      bestC = 1;
      bestVisible = math.min(itemCount, ((innerH + sY) / ((innerW) / aspectRatio + sY)).floor());
      bestUsedArea = 0;
    }

    return _BestPick(columns: bestC, visible: bestVisible, usedArea: bestUsedArea);
  }
}

class _GridConfig {
  final int columns;
  final ScrollPhysics? physics;
  const _GridConfig({required this.columns, this.physics});
}

class _BestPick {
  final int columns;
  final int visible;
  final double usedArea;
  const _BestPick({required this.columns, required this.visible, required this.usedArea});
}
