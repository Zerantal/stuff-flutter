// lib/shared/widgets/entity_description.dart
import 'package:flutter/material.dart';

import '../../App/theme.dart';

class EntityDescription extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? badges; // chips / counts / tags

  const EntityDescription({super.key, required this.title, this.subtitle, this.badges});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final children = <Widget>[
      Text(title, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis, maxLines: 2),
      if (subtitle != null && subtitle!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(subtitle!, style: theme.textTheme.bodySmall),
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
