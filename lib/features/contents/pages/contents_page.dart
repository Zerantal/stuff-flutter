// lib/features/contents/pages/contents_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_routes_ext.dart';
import '../../../shared/image/image_ref.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/context_action_menu.dart';
import '../../../shared/widgets/gesture_wrapped_thumbnail.dart';
import '../../../shared/widgets/empty_list_state.dart';
import '../../../shared/widgets/responsive_entity_sliver.dart';
import '../viewmodels/contents_view_model.dart';

final Logger _log = Logger('ContentsPage');

class ContentsPage extends StatelessWidget {
  const ContentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Pull just what we need; avoid rebuilding the whole page on unrelated changes.
    final containersStream = context.select<ContentsViewModel, Stream<List<ContainerListItem>>>(
      (m) => m.containersStream,
    );
    final itemsStream = context.select<ContentsViewModel, Stream<List<ItemListItem>>>(
      (m) => m.itemsStream,
    );

    return Scaffold(
      key: const ValueKey('ContentsPage'),
      appBar: AppBar(title: const Text('Contents')),
      body: StreamBuilder(
        stream: containersStream,
        builder: (context, contSnap) {
          return StreamBuilder(
            stream: itemsStream,
            builder: (context, itemSnap) {
              final containers = contSnap.data ?? const <ContainerListItem>[];
              final items = itemSnap.data ?? const <ItemListItem>[];

              final isInitialLoading =
                  (contSnap.connectionState == ConnectionState.waiting && !contSnap.hasData) ||
                  (itemSnap.connectionState == ConnectionState.waiting && !itemSnap.hasData);

              final nothingToShow = !isInitialLoading && containers.isEmpty && items.isEmpty;

              return CustomScrollView(
                slivers: [
                  if (nothingToShow)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyListState(text: 'No contents yet/nAdd containers or items.'),
                    )
                  else ...[
                    if (containers.isNotEmpty) ...[
                      _sectionHeader('Containers'),
                      ResponsiveEntitySliver<ContainerListItem>(
                        items: containers,
                        headerBuilder: (ctx, item) => GestureWrappedThumbnail(
                          images: item.images,
                          entityId: item.container.id,
                          entityName: item.container.name,
                          size: 80,
                          borderRadius: 10,
                          fit: BoxFit.contain,
                          placeholder: const ImageRef.asset('assets/images/image_placeholder.png'),
                        ),
                        bodyBuilder: (ctx, c) =>
                            _Body(title: c.container.name, subtitle: c.container.description),
                        trailingBuilder: (ctx, it) => ContextActionMenu(
                          onView: () => AppRoutes.containerContents.push(
                            context,
                            pathParams: {'containerId': it.container.id},
                          ),
                          onEdit: () => AppRoutes.containerEdit.push(
                            ctx,
                            pathParams: {'containerId': it.container.id},
                          ),
                          onDelete: () => _confirmDelete(context, it),
                        ),
                        // Tap handling (wire to your router if desired)
                        onTap: (c) {
                          AppRoutes.containerContents.push(
                            context,
                            pathParams: {'containerId': c.container.id},
                          );
                        },
                      ),
                    ],

                    if (items.isNotEmpty) ...[
                      _sectionHeader('Items'),
                      ResponsiveEntitySliver<ItemListItem>(
                        items: items,
                        headerBuilder: (ctx, item) => GestureWrappedThumbnail(
                          images: item.images,
                          entityId: item.item.id,
                          entityName: item.item.name,
                          size: 80,
                          borderRadius: 10,
                          fit: BoxFit.contain,
                          placeholder: const ImageRef.asset('assets/images/image_placeholder.png'),
                        ),
                        bodyBuilder: (ctx, it) => _Body(
                          title: it.item.name,
                          subtitle: (it.item.description?.isNotEmpty ?? false)
                              ? it.item.description
                              : null,
                        ),
                        trailingBuilder: null,
                        onTap: (it) {
                          // TODO: navigate to item view/edit
                          // AppRoutes.itemViewCanonical.go(ctx, itemId: it.id!);
                        },
                      ),
                    ],
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ContainerListItem c) async {
    final vm = context.read<ContentsViewModel>();

    // capture before async gap to avoid use_build_context_synchronously lint
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ConfirmationDialog.show(
      context,
      title: 'Delete container?',
      message: 'This will permanently delete this container and all of its contents.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      danger: true,
    );

    if (ok == true) {
      try {
        await vm.deleteContainer(c.container.id);
        messenger.showSnackBar(const SnackBar(content: Text('Location deleted')));
      } catch (e, s) {
        messenger.showSnackBar(const SnackBar(content: Text('Delete failed')));
        _log.severe('Failed to delete location', e, s);
      }
    }
  }

  /// Section header that works as a sliver
  SliverToBoxAdapter _sectionHeader(String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (subtitle != null && subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Text(
              subtitle!,
              style: t.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
