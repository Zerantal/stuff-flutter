// lib/shared/widgets/entity_description.dart
import 'package:flutter/material.dart';

import '../../App/theme.dart';

class EntityDescription extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? extra; // (e.g. address row)
  final List<Widget>? badges; // chips / counts / tags

  const EntityDescription({
    super.key,
    required this.title,
    this.description,
    this.badges,
    this.extra,
  });

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
      if (badges != null && badges!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Wrap(spacing: AppSpacing.sm, runSpacing: -AppSpacing.sm, children: badges!),
        ),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
