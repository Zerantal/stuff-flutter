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

    // Grid tile layout
    this.gridHeaderHeight,
    this.gridBodyHeight,
    this.gridTileVerticalPadding,

    // Spacing
    this.outerPadding = const EdgeInsets.fromLTRB(12, 12, 12, 88),
    this.gridMainAxisSpacing = 12.0,
    this.gridCrossAxisSpacing = 12.0,

    // List layout
    this.listSeparatorBuilder,
  });

  final List<T> items;

  // Slots
  final Widget Function(BuildContext context, T item, bool isGridView) headerBuilder;
  final Widget Function(BuildContext context, T item, bool isGridView) bodyBuilder;
  final Widget Function(BuildContext context, T item)? trailingBuilder;
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
  final double? gridBodyHeight;
  final double? gridTileVerticalPadding;

  // Grid spacing/padding
  final double gridMainAxisSpacing;
  final double gridCrossAxisSpacing;

  // Shared outer padding (applies in both list & grid mode)
  final EdgeInsets outerPadding;

  // List layout
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
    final resolvedGridBodyHeight = gridBodyHeight ?? ext.gridBodyHeight;
    final resolvedGridTileVPad = gridTileVerticalPadding ?? ext.gridTileVerticalPadding;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.crossAxisExtent;
        final isGrid = cross >= gridBreakpoint;

        if (!isGrid) {
          final sep = listSeparatorBuilder ?? (ctx, _) => const Divider(height: 1, thickness: 0.6);
          final childCount = items.isEmpty ? 0 : math.max(0, items.length * 2 - 1);

          return SliverPadding(
            padding: outerPadding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                if (i.isOdd) return sep(ctx, i ~/ 2);
                final idx = i ~/ 2;
                final item = items[idx];
                return _ListTile(
                  header: headerBuilder(ctx, item, false),
                  body: bodyBuilder(ctx, item, false),
                  trailing: trailingBuilder?.call(ctx, item),
                  onTap: onTap == null ? null : () => onTap!(item),
                );
              }, childCount: childCount),
            ),
          );
        }

        final tileHeight =
            resolvedGridTileVPad + // total vertical padding
            resolvedGridHeaderHeight +
            resolvedGridBodyHeight;

        // Base inner width after static padding
        final innerBase = math.max(0.0, cross - outerPadding.left - outerPadding.right);

        int columns;
        EdgeInsets snappedPadding = outerPadding;

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

          // Adjust only left/right padding based on snapAlign
          switch (snapAlign) {
            case SnapAlign.left:
              snappedPadding = outerPadding.copyWith(right: outerPadding.right + extra);
              break;
            case SnapAlign.center:
              final hPad = extra / 2.0;
              snappedPadding = outerPadding.copyWith(
                left: outerPadding.left + hPad,
                right: outerPadding.right + hPad,
              );
              break;
            case SnapAlign.right:
              snappedPadding = outerPadding.copyWith(left: outerPadding.left + extra);
              break;
          }
        } else {
          columns = 0; // fallback to MaxCrossAxisExtent delegate
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

              return _GridTile(
                header: headerBuilder(ctx, item, true),
                body: bodyBuilder(ctx, item, true),
                trailing: trailing,
                onTap: onTap == null ? null : () => onTap!(item),
                headerHeight: resolvedGridHeaderHeight,
                gridBodyHeight: resolvedGridBodyHeight,
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
  const _ListTile({required this.header, required this.body, this.trailing, this.onTap});

  final Widget header;
  final Widget body;
  final Widget? trailing;
  final VoidCallback? onTap;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
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
    required this.gridBodyHeight,
    required this.paddingV,
  });

  final Widget header;
  final Widget body;
  final Widget? trailing;
  final VoidCallback? onTap;

  final double headerHeight;
  final double gridBodyHeight;
  final double paddingV;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero, // <--- override global theme margin
      elevation: theme.cardTheme.elevation ?? AppElevation.low,
      shape:
          theme.cardTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: paddingV / 2, horizontal: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: headerHeight, child: header),
                  const Spacer(),
                  if (trailing != null)
                    Padding(padding: const EdgeInsets.only(left: 8.0), child: trailing),
                ],
              ),
              SizedBox(height: gridBodyHeight, child: body),
            ],
          ),
        ),
      ),
    );
  }
}
