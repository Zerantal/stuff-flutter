// lib/features/location/widgets/skeleton_tile.dart
import 'package:flutter/material.dart';

/// Simple skeleton placeholder row used during initial load.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    Widget box(double w, double h, {BorderRadius? r}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: r ?? BorderRadius.circular(6)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          box(80, 80, r: BorderRadius.circular(8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(double.infinity, 16),
                const SizedBox(height: 8),
                box(180, 14),
                const SizedBox(height: 6),
                box(120, 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
