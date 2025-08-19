// lib/shared/widgets/responsive_entity_list.dart
import 'package:flutter/material.dart';
import 'entity_item.dart';

/// A generic responsive list that switches between list and grid layouts
/// based on available width. It renders three declarative **slots** for each
/// item: [thumbnail], [description], and optional [trailing].
///
/// Provide separate builders for list and grid to fine-tune sizes.
class ResponsiveEntityList<T> extends StatelessWidget {
  const ResponsiveEntityList({
    super.key,
    required this.items,
    required this.thumbnailBuilder,
    required this.descriptionBuilder,
    this.trailingBuilder,
    this.onTap,
    // Grid-specific overrides (optional)
    this.gridThumbnailBuilder,
    this.gridDescriptionBuilder,
    this.gridTrailingBuilder,
    // Layout tuning
    this.gridBreakpoint = 720,
    this.crossAxisCount = 2,
    this.gridChildAspectRatio = 1.25,
    this.listPadding = const EdgeInsets.only(bottom: 88, top: 8),
    this.gridPadding = const EdgeInsets.fromLTRB(12, 12, 12, 96),
    this.gridMainAxisSpacing = 12,
    this.gridCrossAxisSpacing = 12,
    this.listSeparatorBuilder,
  });

  final List<T> items;

  // List builders
  final Widget Function(BuildContext context, T item) thumbnailBuilder;
  final Widget Function(BuildContext context, T item) descriptionBuilder;
  final Widget Function(BuildContext context, T item)? trailingBuilder;
  final void Function(T item)? onTap;

  // Grid builders (fallback to list builders if not provided)
  final Widget Function(BuildContext context, T item)? gridThumbnailBuilder;
  final Widget Function(BuildContext context, T item)? gridDescriptionBuilder;
  final Widget Function(BuildContext context, T item)? gridTrailingBuilder;

  // Layout options
  final double gridBreakpoint;
  final int crossAxisCount;
  final double gridChildAspectRatio;
  final EdgeInsets listPadding;
  final EdgeInsets gridPadding;
  final double gridMainAxisSpacing;
  final double gridCrossAxisSpacing;
  final Widget Function(BuildContext, int)? listSeparatorBuilder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isGrid = width >= gridBreakpoint;
        if (!isGrid) {
          return ListView.separated(
            padding: listPadding,
            itemCount: items.length,
            separatorBuilder: listSeparatorBuilder ?? (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              return EntityListItem(
                key: ValueKey(item),
                thumbnail: thumbnailBuilder(context, item),
                description: descriptionBuilder(context, item),
                trailing: trailingBuilder?.call(context, item),
                onTap: onTap == null ? null : () => onTap!(item),
              );
            },
          );
        }

        final thumbB = gridThumbnailBuilder ?? thumbnailBuilder;
        final descB = gridDescriptionBuilder ?? descriptionBuilder;
        final trailB = gridTrailingBuilder ?? trailingBuilder;

        return GridView.builder(
          padding: gridPadding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: gridMainAxisSpacing,
            crossAxisSpacing: gridCrossAxisSpacing,
            childAspectRatio: gridChildAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return EntityGridItem(
              thumbnail: thumbB(context, item),
              description: descB(context, item),
              trailing: trailB?.call(context, item),
              onTap: onTap == null ? null : () => onTap!(item),
            );
          },
        );
      },
    );
  }
}
