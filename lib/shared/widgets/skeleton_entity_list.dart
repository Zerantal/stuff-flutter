// lib/shared/widgets/skeleton_entity_list.dart
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import 'responsive_entity_list.dart';

/// Responsive skeleton list that matches the layout of [ResponsiveEntityList].
/// [numRows] controls the total number of text rows (including the title row).
class SkeletonEntityList extends StatelessWidget {
  final int count;
  final int numRows; // total rows, including title

  const SkeletonEntityList({super.key, this.count = 6, this.numRows = 2});

  double _lineHeight(BuildContext context, TextStyle? style) {
    if (style == null) return 14.0;
    final fs = style.fontSize ?? 14.0;
    final lh = style.height ?? 1.0;
    return fs * lh;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    Widget box(double w, double h, {BorderRadius? r}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: r ?? BorderRadius.circular(AppRadius.sm)),
    );

    final titleHeight = _lineHeight(context, theme.textTheme.titleMedium);
    final bodyHeight = _lineHeight(context, theme.textTheme.bodySmall);

    // Estimate height based on number of rows (overestimate by 1 row)
    final estimatedHeight = titleHeight + (numRows) * (bodyHeight + AppSpacing.xs);

    return ResponsiveEntityList<int>(
      listHeaderHeight: estimatedHeight,
      listHeaderWidth: estimatedHeight,
      gridBodyTargetHeight: estimatedHeight,
      items: List.generate(count, (i) => i),
      onTap: null,
      headerBuilder: (ctx, _) => box(
        // box will be sized according to listHeaderWidth and listHeaderHeight
        0,
        0,
        r: BorderRadius.circular(AppRadius.md),
      ),
      bodyBuilder: (ctx, _) => SizedBox(
        height: estimatedHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,

          children: List.generate(numRows, (i) {
            return box(
              i == 0 ? double.infinity : 100 + (i * 40.0),
              i == 0 ? titleHeight : bodyHeight,
            );
          }),
        ),
      ),
    );
  }
}
