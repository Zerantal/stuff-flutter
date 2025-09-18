import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../app/theme.dart';
import 'entity_tile_theme.dart';

enum SnapAlign { left, center, right }

class ResponsiveEntitySliver<T> extends StatelessWidget {
  const ResponsiveEntitySliver({
    super.key,
    required this.items,
    required this.headerBuilder,
    required this.bodyBuilder,
    this.trailingBuilder,
    this.onTap,

    // Switch breakpoint
    this.gridBreakpoint = 720.0,

    // Tile width behavior
    this.snapToTileWidth = true,
    this.snapAlign = SnapAlign.left,

    this.gridTileWidth = 240.0,
    this.gridMinColumns = 2,
    this.gridMaxColumns = 8,

    // Density & Theme
    this.density = EntityTileDensity.comfy,

    // Grid tile layout (nullable => take from ThemeExtension/preset)
    this.gridHeaderHeight,
    this.gridBodyTargetHeight,
    this.gridTrailingHeight,
    this.forceGridTrailingSpace = false,
    this.gridSectionGap,
    this.gridTileVerticalPadding,

    // Spacing/padding
    this.gridPadding = const EdgeInsets.fromLTRB(12, 12, 12, 96),
    this.gridMainAxisSpacing = 12.0,
    this.gridCrossAxisSpacing = 12.0,

    // List layout (nullable => ThemeExtension/preset)
    this.listHeaderWidth,
    this.listHeaderHeight,
    this.listTileMinHeight,
    this.listPadding = const EdgeInsets.only(top: 8, bottom: 88),
    this.listSeparatorBuilder,
  });

  final List<T> items;

  // Slots
  final Widget Function(BuildContext, T) headerBuilder;
  final Widget Function(BuildContext, T) bodyBuilder;
  final Widget Function(BuildContext, T)? trailingBuilder;
  final void Function(T item)? onTap;

  // Breakpoint
  final double gridBreakpoint;

  // Width snapping
  final bool snapToTileWidth;
  final SnapAlign snapAlign;
  final double gridTileWidth;
  final int gridMinColumns;
  final int gridMaxColumns;

  // Density & Theme
  final EntityTileDensity density;

  // Grid tile layout (nullable to allow theme defaults)
  final double? gridHeaderHeight;
  final double? gridBodyTargetHeight;
  final double? gridTrailingHeight;
  final bool forceGridTrailingSpace;
  final double? gridSectionGap;
  final double? gridTileVerticalPadding;

  // Grid spacing/padding
  final EdgeInsets gridPadding;
  final double gridMainAxisSpacing;
  final double gridCrossAxisSpacing;

  // List layout (nullable to allow theme defaults)
  final double? listHeaderWidth;
  final double? listHeaderHeight;
  final double? listTileMinHeight;
  final EdgeInsets listPadding;
  final Widget Function(BuildContext, int)? listSeparatorBuilder;

  EntityTileTheme _resolveTheme(BuildContext context) {
    // Prefer app theme extension, otherwise use the density preset locally.
    return Theme.of(context).extension<EntityTileTheme>() ?? EntityTileTheme.preset(density);
  }

  @override
  Widget build(BuildContext context) {
    final ext = _resolveTheme(context);

    // Resolve all nullable sizing from theme extension (with local overrides)
    final resolvedGridHeaderHeight = gridHeaderHeight ?? ext.gridHeaderHeight;
    final resolvedGridBodyTargetHeight = gridBodyTargetHeight ?? ext.gridBodyTargetHeight;
    final resolvedGridTrailingHeight = gridTrailingHeight ?? ext.gridTrailingHeight;
    final resolvedGridSectionGap = gridSectionGap ?? ext.gridSectionGap;
    final resolvedGridTileVPad = gridTileVerticalPadding ?? ext.gridTileVerticalPadding;

    final resolvedListHeaderWidth = listHeaderWidth ?? ext.listHeaderWidth;
    final resolvedListHeaderHeight = listHeaderHeight ?? ext.listHeaderHeight;
    final resolvedListTileMinHeight = listTileMinHeight ?? ext.listTileMinHeight;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.crossAxisExtent;
        final isGrid = cross >= gridBreakpoint;

        if (!isGrid) {
          final sep = listSeparatorBuilder ?? (ctx, _) => const Divider(height: 1, thickness: 0.6);
          final childCount = items.isEmpty ? 0 : math.max(0, items.length * 2 - 1);

          return SliverPadding(
            padding: listPadding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                if (i.isOdd) return sep(ctx, i ~/ 2);
                final idx = i ~/ 2;
                final item = items[idx];
                return _ListTile(
                  minHeight: resolvedListTileMinHeight,
                  headerWidth: resolvedListHeaderWidth,
                  headerHeight: resolvedListHeaderHeight,
                  header: headerBuilder(ctx, item),
                  body: bodyBuilder(ctx, item),
                  trailing: trailingBuilder?.call(ctx, item),
                  onTap: onTap == null ? null : () => onTap!(item),
                );
              }, childCount: childCount),
            ),
          );
        }

        final hasTrailingBuilder = trailingBuilder != null;
        final reserveTrailing = forceGridTrailingSpace || hasTrailingBuilder;

        // Auto default if user forgot to set a height
        final effectiveTrailingHeight = reserveTrailing
            ? ((resolvedGridTrailingHeight > 0) ? resolvedGridTrailingHeight : 40.0)
            : 0.0;

        // Compute fixed tile height (body will Expand to fill; no overflow)
        final gaps = resolvedGridSectionGap + (reserveTrailing ? resolvedGridSectionGap : 0);
        final tileHeight =
            resolvedGridTileVPad +
            resolvedGridHeaderHeight +
            gaps +
            effectiveTrailingHeight +
            resolvedGridBodyTargetHeight;

        // Base inner width after static padding
        final innerBase = math.max(0.0, cross - gridPadding.left - gridPadding.right);

        int columns;
        EdgeInsets snappedPadding = gridPadding;

        if (snapToTileWidth) {
          int c = ((innerBase + gridCrossAxisSpacing) / (gridTileWidth + gridCrossAxisSpacing))
              .floor();
          c = c.clamp(gridMinColumns, gridMaxColumns);
          if (c < 1) c = 1;

          // Make sure the desired inner actually fits; reduce c if needed.
          double desiredInner = c * gridTileWidth + (c - 1) * gridCrossAxisSpacing;
          while (c > 1 && desiredInner > innerBase + 0.5) {
            c--;
            desiredInner = c * gridTileWidth + (c - 1) * gridCrossAxisSpacing;
          }
          columns = c;

          final extra = math.max(0.0, innerBase - desiredInner);

          // Align the snapped inner area
          switch (snapAlign) {
            case SnapAlign.left:
              snappedPadding = gridPadding.copyWith(right: gridPadding.right + extra);
              break;
            case SnapAlign.center:
              final hPad = extra / 2.0;
              snappedPadding = gridPadding.copyWith(
                left: gridPadding.left + hPad,
                right: gridPadding.right + hPad,
              );
              break;
            case SnapAlign.right:
              snappedPadding = gridPadding.copyWith(left: gridPadding.left + extra);
              break;
          }
        } else {
          columns = 0; // we’ll use MaxCrossAxisExtent delegate
        }

        return SliverPadding(
          padding: snappedPadding,
          sliver: SliverGrid(
            gridDelegate: (snapToTileWidth && columns > 0)
                ? SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: tileHeight,
                    mainAxisSpacing: gridMainAxisSpacing,
                    crossAxisSpacing: gridCrossAxisSpacing,
                  )
                : SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: gridTileWidth,
                    mainAxisExtent: tileHeight,
                    mainAxisSpacing: gridMainAxisSpacing,
                    crossAxisSpacing: gridCrossAxisSpacing,
                  ),
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final item = items[i];
              final trailing = trailingBuilder?.call(ctx, item);
              final showTrailing = reserveTrailing && trailing != null;

              return _GridTile(
                header: headerBuilder(ctx, item),
                body: bodyBuilder(ctx, item),
                trailing: showTrailing ? trailing : null,
                onTap: onTap == null ? null : () => onTap!(item),
                headerHeight: resolvedGridHeaderHeight,
                trailingHeight: effectiveTrailingHeight,
                gap: resolvedGridSectionGap,
                paddingV: resolvedGridTileVPad,
              );
            }, childCount: items.length),
          ),
        );
      },
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.header,
    required this.body,
    this.trailing,
    this.onTap,
    required this.headerWidth,
    required this.headerHeight,
    required this.minHeight,
  });

  final Widget header;
  final Widget body;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double headerWidth;
  final double headerHeight;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      elevation: theme.cardTheme.elevation ?? AppElevation.low,
      shape:
          theme.cardTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: headerWidth, height: headerHeight, child: header),
                const SizedBox(width: 12),
                Expanded(child: body),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Align(alignment: Alignment.topRight, child: trailing!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.header,
    required this.body,
    this.trailing,
    this.onTap,
    required this.headerHeight,
    required this.trailingHeight,
    required this.gap,
    required this.paddingV,
  });

  final Widget header;
  final Widget body;
  final Widget? trailing;
  final VoidCallback? onTap;

  final double headerHeight;
  final double trailingHeight;
  final double gap;
  final double paddingV;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: theme.cardTheme.elevation ?? AppElevation.low,
      shape:
          theme.cardTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: headerHeight, child: header),
              SizedBox(height: gap),
              Expanded(child: body), // absorbs rounding; no overflow
              if (trailing != null && trailingHeight > 0) ...[
                SizedBox(height: gap),
                SizedBox(
                  height: trailingHeight,
                  child: Align(alignment: Alignment.topRight, child: trailing),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
