// lib/shared/widgets/entity_item.dart
import 'package:flutter/material.dart';

class EntityListItem extends StatelessWidget {
  final Widget thumbnail; // slot
  final Widget description; // slot (usually EntityDescription)
  final Widget? trailing; // slot (usually ContextActionMenu)
  final VoidCallback? onTap;

  const EntityListItem({
    super.key,
    required this.thumbnail,
    required this.description,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(right: 12), child: thumbnail),
            Expanded(child: description),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class EntityGridItem extends StatelessWidget {
  final Widget thumbnail; // slot (fills header area)
  final Widget description; // slot
  final Widget? trailing; // slot (actions menu)
  final VoidCallback? onTap;

  const EntityGridItem({
    super.key,
    required this.thumbnail,
    required this.description,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 120, child: thumbnail),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: description),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
