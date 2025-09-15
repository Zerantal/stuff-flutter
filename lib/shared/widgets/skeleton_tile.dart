// lib/features/location/widgets/skeleton_tile.dart
import 'package:flutter/material.dart';

import '../../App/theme.dart';
import 'entity_tile_theme.dart';

/// Simple skeleton placeholder row used during initial load.
class SkeletonTile extends StatelessWidget {
  final int numRows;
  final double? tileHeight;

  const SkeletonTile({super.key, this.numRows = 2, this.tileHeight});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    // Default tile height from theme extension (fallback to 88 like comfy preset)
    final ext = Theme.of(context).extension<EntityTileTheme>();
    final effectiveTileHeight = tileHeight ?? ext?.listTileMinHeight ?? 88.0;

    Widget box(double w, double h, {BorderRadius? r}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: r ?? BorderRadius.circular(AppRadius.sm)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: SizedBox(
        height: effectiveTileHeight,
        child: Row(
          children: [
            // Square thumbnail = same as tile height
            box(effectiveTileHeight, effectiveTileHeight, r: BorderRadius.circular(AppRadius.md)),
            const SizedBox(width: AppSpacing.md - AppSpacing.xs), // ~12
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  box(double.infinity, 16), // title skeleton
                  for (int i = 0; i < numRows; i++) ...[
                    const SizedBox(height: AppSpacing.xs),
                    box(180 - i * 40.0, 14), // variable widths for realism
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
