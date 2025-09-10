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

enum _AddAction { container, item }

class ContentsPage extends StatelessWidget {
  const ContentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ContentsViewModel>();

    // Pull just what we need; avoid rebuilding the whole page on unrelated changes.
    final containersStream = context.select<ContentsViewModel, Stream<List<ContainerListItem>>>(
      (m) => m.containersStream,
    );
    final itemsStream = context.select<ContentsViewModel, Stream<List<ItemListItem>>>(
      (m) => m.itemsStream,
    );

    final width = MediaQuery.sizeOf(context).width;
    final useExtendedFab = width >= 720; // wide screens get an extended FAB

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
                      child: EmptyListState(text: 'No contents yet!\nAdd containers or items.'),
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
                          onDelete: () => _confirmDeleteContents(context, it),
                        ),
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
                        trailingBuilder: (ctx, it) => ContextActionMenu(
                          onView: () =>
                              AppRoutes.itemView.push(context, pathParams: {'itemId': it.item.id}),
                          onEdit: () =>
                              AppRoutes.itemEdit.push(ctx, pathParams: {'itemId': it.item.id}),
                          onDelete: () => _confirmDeleteItem(context, it),
                        ),
                        onTap: (c) {
                          AppRoutes.itemView.push(context, pathParams: {'itemId': c.item.id});
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
      floatingActionButton: _buildFab(context, vm, useExtendedFab),
    );
  }

  /// Builds a FAB only for room/container scopes.
  Widget? _buildFab(BuildContext context, ContentsViewModel vm, bool extended) {
    return vm.scope.map(
      all: () => null,
      location: (_) => null,
      room: (roomId) {
        return PopupMenuButton<_AddAction>(
          tooltip: 'Add',
          position: PopupMenuPosition.over,
          onSelected: (choice) {
            switch (choice) {
              case _AddAction.container:
                AppRoutes.containerAddToRoom.push(context, pathParams: {'roomId': roomId});
                break;
              case _AddAction.item:
                AppRoutes.itemAddToRoom.push(context, pathParams: {'roomId': roomId});
                break;
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(
              value: _AddAction.container,
              child: ListTile(leading: Icon(Icons.archive_outlined), title: Text('Add Container')),
            ),
            PopupMenuItem(
              value: _AddAction.item,
              child: ListTile(leading: Icon(Icons.inventory_2_outlined), title: Text('Add Item')),
            ),
          ],
          child: extended
              ? const FloatingActionButton.extended(
                  icon: Icon(Icons.add),
                  label: Text('Add'),
                  onPressed: null,
                )
              : const FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
        );
      },
      container: (containerId) {
        return PopupMenuButton<_AddAction>(
          tooltip: 'Add',
          position: PopupMenuPosition.over,
          onSelected: (choice) {
            switch (choice) {
              case _AddAction.container:
                AppRoutes.containerAddToContainer.push(
                  context,
                  pathParams: {'containerId': containerId},
                );
                break;
              case _AddAction.item:
                AppRoutes.itemAddToContainer.push(
                  context,
                  pathParams: {'containerId': containerId},
                );
                break;
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(
              value: _AddAction.container,
              child: ListTile(
                leading: Icon(Icons.archive_outlined),
                title: Text('Add Sub-Container'),
              ),
            ),
            PopupMenuItem(
              value: _AddAction.item,
              child: ListTile(leading: Icon(Icons.inventory_2_outlined), title: Text('Add Item')),
            ),
          ],
          child: extended
              ? const FloatingActionButton.extended(
                  icon: Icon(Icons.add),
                  label: Text('Add'),
                  onPressed: null,
                )
              : const FloatingActionButton(onPressed: null, child: Icon(Icons.add)),
        );
      },
    );
  }

  Future<void> _confirmDeleteContents(BuildContext context, ContainerListItem c) async {
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
        messenger.showSnackBar(const SnackBar(content: Text('Container deleted')));
      } catch (e, s) {
        messenger.showSnackBar(const SnackBar(content: Text('Delete failed')));
        _log.severe('Failed to delete container', e, s);
      }
    }
  }

  Future<void> _confirmDeleteItem(BuildContext context, ItemListItem i) async {
    final vm = context.read<ContentsViewModel>();

    // capture before async gap to avoid use_build_context_synchronously lint
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ConfirmationDialog.show(
      context,
      title: 'Delete item?',
      message: 'This will permanently delete this item.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      danger: true,
    );

    if (ok == true) {
      try {
        await vm.deleteItem(i.item.id);
        messenger.showSnackBar(const SnackBar(content: Text('Item deleted')));
      } catch (e, s) {
        messenger.showSnackBar(const SnackBar(content: Text('Delete failed')));
        _log.severe('Failed to delete item', e, s);
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
