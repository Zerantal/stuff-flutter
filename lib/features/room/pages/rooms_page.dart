// lib/features/room/pages/rooms_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../app/routing/app_routes_ext.dart';
import '../../../app/routing/app_routes.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/context_action_menu.dart';
import '../../../shared/widgets/gesture_wrapped_thumbnail.dart';
import '../../../shared/widgets/entity_description.dart';
import '../../../shared/widgets/responsive_entity_list.dart';
import '../viewmodels/rooms_view_model.dart';
import '../../../shared/widgets/skeleton_tile.dart';
import '../../../shared/widgets/empty_list_state.dart';

final _log = Logger('RoomsPage');

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useExtendedFab = width >= 720;
    final vm = context.read<RoomsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rooms'),
            if (vm.locationName != null)
              Text(vm.locationName!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: _buildBody(vm),
      floatingActionButton: useExtendedFab
          ? FloatingActionButton.extended(
              key: const ValueKey('add_room_fab'),
              heroTag: 'roomsPageFAB',
              onPressed: () =>
                  AppRoutes.roomsAdd.push(context, pathParams: {'locationId': vm.locationId}),
              icon: const Icon(Icons.add_outlined),
              label: const Text('Add Room'),
            )
          : FloatingActionButton(
              key: const ValueKey('add_room_fab'),
              heroTag: 'roomsPageFAB',
              onPressed: () =>
                  AppRoutes.roomsAdd.push(context, pathParams: {'locationId': vm.locationId}),
              tooltip: 'Add Room',
              child: const Icon(Icons.add_outlined),
            ),
    );
  }

  Widget _buildBody(RoomsViewModel vm) {
    return StreamBuilder<List<RoomListItem>>(
      stream: vm.rooms,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88, top: 8),
            itemCount: 6,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, _) => const SkeletonTile(),
          );
        }

        final items = snapshot.data ?? const <RoomListItem>[];
        if (items.isEmpty) {
          return EmptyListState(
            onAdd: () =>
                AppRoutes.roomsAdd.push(context, pathParams: {'locationId': vm.locationId}),
            text: "No rooms yet\nAdd your first room for this location",
            buttonText: "Add room",
            buttonIcon: const Icon(Icons.add_outlined),
          );
        }

        return ResponsiveEntityList<RoomListItem>(
          items: items,
          onTap: (it) => AppRoutes.roomContents.push(
            context,
            pathParams: {'locationId': vm.locationId, 'roomId': it.room.id},
          ),
          thumbnailBuilder: (ctx, it) => it.images.isNotEmpty
              ? GestureWrappedThumbnail(
                  images: it.images,
                  entityId: it.room.id,
                  entityName: it.room.name,
                  size: 80,
                )
              : Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.meeting_room),
                ),
          descriptionBuilder: (ctx, it) =>
              EntityDescription(title: it.room.name, subtitle: it.room.description),
          trailingBuilder: (ctx, it) => ContextActionMenu(
            onView: () => AppRoutes.roomContents.push(
              context,
              pathParams: {'locationId': vm.locationId, 'roomId': it.room.id},
            ),
            onEdit: () => AppRoutes.roomsEdit.push(
              ctx,
              pathParams: {'locationId': vm.locationId, 'roomId': it.room.id},
            ),
            onDelete: () => _confirmDelete(context, vm, it),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, RoomsViewModel vm, RoomListItem rm) async {
    // capture before async gap to avoid use_build_context_synchronously lint
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ConfirmationDialog.show(
      context,
      title: 'Delete location?',
      message: 'This will permanently delete this location and its photos.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      danger: true,
    );

    if (ok == true) {
      try {
        await vm.deleteRoom(rm.room.id);
        messenger.showSnackBar(const SnackBar(content: Text('Location deleted')));
      } catch (e, s) {
        messenger.showSnackBar(const SnackBar(content: Text('Delete failed')));
        _log.severe('Failed to delete location', e, s);
      }
    }
  }
}
