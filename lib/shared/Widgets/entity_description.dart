// lib/shared/widgets/entity_description.dart
import 'package:flutter/material.dart';

class EntityDescription extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? badges; // chips / counts / tags

  const EntityDescription({super.key, required this.title, this.subtitle, this.badges});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      if (subtitle != null && subtitle!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ),
      if (badges != null && badges!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 6, runSpacing: -8, children: badges!),
        ),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
