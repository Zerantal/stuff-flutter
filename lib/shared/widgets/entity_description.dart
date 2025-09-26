// lib/shared/widgets/entity_description.dart
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class EntityDescription extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? extra; // (e.g. address row)

  const EntityDescription({super.key, required this.title, this.description, this.extra});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final children = <Widget>[
      Text(title, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
      if (description != null && description!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            description!,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      if (extra != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: extra!,
        ),
    ];
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      ),
    );
  }

  // ---------------- Height estimator for grid view tile -------------------------------//

  /// Measures one line of the given style (respecting textScaleFactor).
  static double _lineHeight(BuildContext context, TextStyle? style) {
    final textScale = MediaQuery.textScalerOf(context);
    final tp = TextPainter(
      text: TextSpan(text: 'Mg', style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScale,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);
    return tp.size.height;
  }

  /// Estimate required height for this entity description.
  ///
  /// [descLines] and [extraLines] are *maximums* you intend to show.
  /// Set [includeDescription]/[includeExtra]/[includeBadges] based on your tile content.
  static double estimateHeight(
    BuildContext context, {
    int descLines = 2,
    int extraLines = 0,
    int badgeRows = 0,
  }) {
    final theme = Theme.of(context).textTheme;

    final titleLineH = _lineHeight(context, theme.titleMedium);
    final bodyLineH = _lineHeight(context, theme.bodySmall);

    double h = 0;

    // EntityDescription has an outer top padding of AppSpacing.sm
    h += AppSpacing.sm;

    // Title (always one line, ellipsized)
    h += titleLineH;

    // Description (optional)
    if (descLines > 0) {
      h += AppSpacing.xs; // top padding before description
      h += bodyLineH * descLines; // max #lines
    }

    // Extra (optional)
    if (extraLines > 0) {
      h += AppSpacing.sm; // top padding before extra
      h += bodyLineH * extraLines; // max #lines
    }

    return h;
  }
}
